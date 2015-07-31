#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "mailman"
require_relative 'lib/mailchimp'
require_relative 'lib/ignore_mail'
require_relative 'lib/get_file'

EMAIL_RESPONDER_ACCOUNT = ENV["EMAIL_RESPONDER_ACCOUNT"] or abort("no environment variable EMAIL_RESPONDER_ACCOUNT")
EMAIL_RESPONDER_PASSWORD = ENV["EMAIL_RESPONDER_PASSWORD"] or abort("no environment variable EMAIL_RESPONDER_PASSWORD")
EMAIL_REPLIER = ENV["EMAIL_REPLIER"] or abort("no environment variable EMAIL_REPLIER")
BODY_TEXT_URL = ENV["BODY_TEXT_URL"] or abort("no environment variable BODY_TEXT_URL")
BODY_HTML_URL = ENV["BODY_HTML_URL"] or abort("no environment variable BODY_HTML_URL")

# For testing, only process mail sent from inside organization
imap_filter = 'UNSEEN FROM getlantern.org'
imap_filter = 'UNSEEN' if ENV["PRODUCTION"] == "true"

Mailman.config.poll_interval = 1
Mailman.config.logger = Logger.new(STDERR) # it's required by Heroku

Mailman.config.imap = {
  server: 'imap.gmail.com', port: 993, ssl: true,
  username: EMAIL_RESPONDER_ACCOUNT,
  password: EMAIL_RESPONDER_PASSWORD,
  filter: imap_filter
}

Mail.defaults do
  delivery_method :smtp,
    address: "smtp.gmail.com",
    port: 587,
    user_name: EMAIL_RESPONDER_ACCOUNT,
    password: EMAIL_RESPONDER_PASSWORD,
    enable_ssl:  true
end

$body_text_file = get_file(BODY_TEXT_URL)
$body_html_file = get_file(BODY_HTML_URL)
if ENV["ATTACHMENT_URL"] then
  $body_html_file = get_file(ENV["ATTACHMENT_URL"])
end

def send_to(to, subject, reply_id)
  begin
    mail = Mail.new

    # below are headers added by gmail auto responder
    mail.header['Precedence'] = 'bulk'
    mail.header['X-Autoreply'] = 'yes'
    mail.header['Auto-Submitted'] = 'auto-replied'

    # connect the reply to original mail
    mail.header['In-Reply-To'] = reply_id
    mail.header['References'] = reply_id

    mail.to = to
    mail.from = EMAIL_REPLIER
    mail.subject = 'Re: ' + subject
    mail.text_part do
      content_transfer_encoding 'base64'
      content_type 'text/plain; charset=UTF-8'
      body File.read($body_text_file)
    end
    mail.html_part do
      content_transfer_encoding 'base64'
      content_type 'text/html; charset=UTF-8'
      body File.read($body_html_file)
    end
    if $attachment_file and File.exist? $attachment_file then
      mail.add_file File.read($attachment_file)
    end

    mail.deliver!
    Mailman.logger.info "Sent respond mail to \'#{to}\'"

  rescue Exception => e
    Mailman.logger.error "Exception occurred while send response:\n#{mail}"
    Mailman.logger.error [e, *e.backtrace].join("\n")
  end
end

Mailman::Application.run do
  from(/no[-_]*reply/) do
    ignore_mail message
  end
  from('mailer-daemon@googlemail.com') do
    ignore_mail message
  end

  default do
    begin
      from = message["From"].address_list.addresses[0].raw
      subject = message["Subject"]
      subject = subject ? subject.value : ''
      msg_id = message["Message-ID"].value
      send_to(from, subject, msg_id)
      name = message["From"].address_list.addresses[0].display_name
      add_to_mailchimp(name, message.from[0])
    rescue Exception => e
      Mailman.logger.error "Exception occurred while processing message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end
end
