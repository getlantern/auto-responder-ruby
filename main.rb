#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "mailman"
require_relative 'lib/mailchimp'
require_relative 'lib/ignore_mail'
require_relative 'lib/get_file'
require_relative 'lib/send'

EMAIL_ACCOUNT = ENV["EMAIL_ACCOUNT"] or abort("no environment variable EMAIL_ACCOUNT")
EMAIL_PASSWORD = ENV["EMAIL_PASSWORD"] or abort("no environment variable EMAIL_PASSWORD")
BODY_TEXT_URL = ENV["BODY_TEXT_URL"] or abort("no environment variable BODY_TEXT_URL")
BODY_HTML_URL = ENV["BODY_HTML_URL"] or abort("no environment variable BODY_HTML_URL")
REPLY_FROM_ADDR = ENV["REPLY_FROM_ADDR"] or abort("no environment variable REPLY_FROM_ADDR")

# For testing, only process mail sent from inside organization
imap_filter = 'UNSEEN FROM getlantern.org'
imap_filter = 'UNSEEN' if ENV["PRODUCTION"] == "true"

Mailman.config.poll_interval = 1
Mailman.config.logger = Logger.new(STDERR) # it's required by Heroku

Mailman.config.imap = {
  server: 'imap.gmail.com', port: 993, ssl: true,
  username: EMAIL_ACCOUNT,
  password: EMAIL_PASSWORD,
  folder: ENV["HANDLE_SPAM"] == "true" ? '[Gmail]/Spam' : 'Inbox',
  filter: imap_filter
}

$body_text_file = get_file(BODY_TEXT_URL)
$body_html_file = get_file(BODY_HTML_URL)
if ENV["ATTACHMENT_URL"] then
  $attachment_file = get_file(ENV["ATTACHMENT_URL"])
end

$stderr.print "Monitor emails to #{EMAIL_ACCOUNT} and reply from #{REPLY_FROM_ADDR}\n"

Mailman::Application.run do
  from(EMAIL_ACCOUNT) do
    ignore_mail message
  end
  from(REPLY_FROM_ADDR) do
    ignore_mail message
  end
  from(/^invit/) do
    ignore_mail message
  end
  from(/no[-_]*reply/) do
    ignore_mail message
  end
  from('mailer-daemon@googlemail.com') do
    ignore_mail message
  end
  from(/^notification\+/) do
    ignore_mail message
  end

  default do
    begin
      from_name = message["From"].address_list.addresses[0].display_name
      from_addr = message.from[0]
      subject = message["Subject"]
      subject = subject ? subject.value : ''
      msg_id = message["Message-ID"].value
      send_to(from_addr, from_name, subject, msg_id)
      add_to_mailchimp(from_name, from_addr)
    rescue Exception => e
      Mailman.logger.error "Exception occurred while processing message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end
end
