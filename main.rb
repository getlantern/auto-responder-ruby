#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "mailman"
require 'base64'
require 'mailchimp'

EMAIL_RESPONDER_ACCOUNT = ENV["EMAIL_RESPONDER_ACCOUNT"] or abort("no environment variable EMAIL_RESPONDER_ACCOUNT")
EMAIL_RESPONDER_PASSWORD = ENV["EMAIL_RESPONDER_PASSWORD"] or abort("no environment variable EMAIL_RESPONDER_PASSWORD")
MAILCHIMP_API_KEY = ENV["MAILCHIMP_API_KEY"] or abort("no environment variable MAILCHIMP_API_KEY")
MAILCHIMP_LIST_ID = ENV["MAILCHIMP_LIST_ID"] or abort("no environment variable MAILCHIMP_LIST_ID")

Mailman.config.logger = Logger.new("log/mailman.log")

Mailman.config.poll_interval = 1

Mailman.config.imap = {
  server: 'imap.gmail.com', port: 993, ssl: true,
  username: EMAIL_RESPONDER_ACCOUNT,
  password: EMAIL_RESPONDER_PASSWORD,
  filter: 'UNSEEN'
}

Mail.defaults do
  delivery_method :smtp,
    address: "smtp.gmail.com",
    port: 587,
    user_name: EMAIL_RESPONDER_ACCOUNT,
    password: EMAIL_RESPONDER_PASSWORD,
    enable_ssl:  true
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
    mail.from = 'Lantern Manoto <manato@getlantern.org>'
    mail.subject = 'Re: ' + subject
    mail.text_part do
      content_transfer_encoding 'base64'
      content_type 'text/plain; charset=UTF-8'
      body Base64.encode64(File.read('content.txt'))
    end
    mail.html_part do
      content_transfer_encoding 'base64'
      content_type 'text/html; charset=UTF-8'
      body Base64.encode64(File.read('content.html'))
    end
    # mail.add_file 'attachment_file'

    mail.deliver!
    Mailman.logger.info "Sent respond mail to \'#{to}\'"

  rescue Exception => e
    Mailman.logger.error "Exception occurred while send response:\n#{mail}"
    Mailman.logger.error [e, *e.backtrace].join("\n")
  end
end

def add_to_mailchimp(name, addr)
  begin
    merge_vars = nil
    if name then
      fname, lname = name.split
      merge_vars = {
        'FNAME' => fname,
        'LNAME' => lname
      }
    end
    mailchimp = Mailchimp::API.new(MAILCHIMP_API_KEY)
    mailchimp.lists.subscribe(MAILCHIMP_LIST_ID,
                              { "email" => addr },
                              merge_vars,
                              'html', # email_type
                              false, # double_optin
                              true) # update_existing
    Mailman.logger.info "Added #{addr} to mailchimp"
  rescue Exception => e
    Mailman.logger.error "Exception occurred while add #{addr} to mailchimp"
    Mailman.logger.error [e, *e.backtrace].join("\n")
  end
end

Mailman::Application.run do
  from(/no[-_]*reply/) do
    begin
      from = message["From"].address_list.addresses[0].raw
      subject = message["Subject"].value
      Mailman.logger.info "Skip no reply mail from #{from}: #{subject}"
    rescue Exception => e
      Mailman.logger.error "Exception occurred while receiving message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end

  default do
    begin
      from = message["From"].address_list.addresses[0].raw
      subject = message["Subject"].value
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
