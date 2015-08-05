require "mailman"
require "mandrill"
require 'base64'
require "pp"

MANDRILL_API_KEY=ENV["MANDRILL_API_KEY"] or abort("no environment variable MANDRILL_API_KEY")
REPLY_FROM_ADDR = ENV["REPLY_FROM_ADDR"] or abort("no environment variable REPLY_FROM_ADDR")
REPLY_FROM_NAME = ENV["REPLY_FROM_NAME"] or abort("no environment variable REPLY_FROM_NAME")

Mail.defaults do
  delivery_method :smtp,
    address: "smtp.mandrillapp.com",
    port: 587,
    user_name: 'getlantern',
    password: MANDRILL_API_KEY,
    enable_ssl:  true
end

# Mail.defaults do
#   delivery_method :smtp,
#     address: "smtp.gmail.com",
#     port: 587,
#     user_name: EMAIL_RESPONDER_ACCOUNT,
#     password: EMAIL_RESPONDER_PASSWORD,
#     enable_ssl:  true
# end
#
def send_to(to_addr, to_name, subject, reply_id)
  send_to_smtp to_addr, to_name, subject, reply_id
end

def send_to_mandrill(to_addr, to_name, subject, reply_id)
  begin
    mandrill = Mandrill::API.new MANDRILL_API_KEY
    message = {
      'html' => File.read($body_html_file),
      'text' => File.read($body_text_file),
      'from_email' => REPLY_FROM_ADDR,
      'from_name' => REPLY_FROM_NAME,
      'subject' => 'Re: ' + subject,
      'to' => [{
        'email' => to_addr,
        'name' => to_name
      }],
      'headers' => {
        # below are headers added by gmail auto responder
        'Precedence' => 'bulk',
        'X-Autoreply' => 'yes',
        'Auto-Submitted' => 'auto-replied',
        # connect the reply to original mail
        'In-Reply-To' => reply_id,
        'References' => reply_id
      }
    }
    p "stripped #{message['html'].size} bytes"
    async = true
    result = mandrill.messages.send message, async
    if result[0]['status'] != 'sent' then
      raise Exception.new("Failed to send mail: #{result}")
    end

  rescue Exception => e
    message['html'] = "stripped #{message['html'].size} bytes"
    message['text'] = "stripped #{message['text'].size} bytes"
    Mailman.logger.error "Exception occurred while send response:\n#{message}"
    Mailman.logger.error [e, *e.backtrace].join("\n")
  end
end

def send_to_smtp(to_addr, to_name, subject, reply_id)
  tries ||=3
  mail = Mail.new

  # below are headers added by gmail auto responder
  mail.header['Precedence'] = 'bulk'
  mail.header['X-Autoreply'] = 'yes'
  mail.header['Auto-Submitted'] = 'auto-replied'

  # connect the reply to original mail
  mail.header['In-Reply-To'] = reply_id
  mail.header['References'] = reply_id

  mail.to = (to_name || '') + ' <' + to_addr + '>'
  mail.from = REPLY_FROM_NAME + ' <' + REPLY_FROM_ADDR + '>'
  mail.subject = 'Re: ' + subject
  mail.text_part do
    content_transfer_encoding 'base64'
    content_type 'text/plain; charset=UTF-8'
    body Base64.encode64(File.read($body_text_file))
  end
  mail.html_part do
    content_transfer_encoding 'base64'
    content_type 'text/html; charset=UTF-8'
    body Base64.encode64(File.read($body_html_file))
  end
  if $attachment_file and File.exist? $attachment_file then
    mail.add_file $attachment_file
  end

  mail.deliver!
  Mailman.logger.info "Sent respond mail to \'#{mail.to}\'"

rescue EOFError
  retry unless (tries -= 1).zero?
rescue Exception => e
  mail.text_part = nil
  mail.html_part = nil
  Mailman.logger.error "Exception occurred while send response:\n#{mail}"
  Mailman.logger.error [e, *e.backtrace].join("\n")
end
