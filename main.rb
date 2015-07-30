#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "mailman"
require 'base64'


Mailman.config.logger = Logger.new("log/mailman.log")

Mailman.config.poll_interval = 1

Mailman.config.imap = {
  server: 'imap.gmail.com', port: 993, ssl: true,
  username: ENV['EMAIL_RESPONDER_ACCOUNT'],
  password: ENV['EMAIL_RESPONDER_PASSWORD'],
  filter: 'UNSEEN FROM getlantern.org'
}

Mail.defaults do
  delivery_method :smtp,
    address: "smtp.gmail.com",
    port: 587,
    user_name: ENV['EMAIL_RESPONDER_ACCOUNT'],
    password: ENV['EMAIL_RESPONDER_PASSWORD'],
    enable_ssl:  true
end

def send_to(to, subject, reply_id)
  mail = Mail.new

  # below are gmail auto responder
  mail.header['Precedence'] = 'bulk'
  mail.header['X-Autoreply'] = 'yes'
  mail.header['Auto-Submitted'] = 'auto-replied'

  # as reply to original mail
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

  from "fffw@getlantern.org" do
    #default do
    begin
      from = message["From"].address_list.addresses[0].raw
      subject = message["Subject"].value
      msg_id = message["Message-ID"].value
      send_to(from, subject, msg_id)
      Mailman.logger.info "Sent respond mail to #{from}"
    rescue Exception => e
      Mailman.logger.error "Exception occurred while receiving message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end
end
