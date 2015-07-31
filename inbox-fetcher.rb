#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "mailman"
require_relative 'lib/mailchimp'
require_relative 'lib/ignore_mail'

EMAIL_RESPONDER_ACCOUNT = ENV["EMAIL_RESPONDER_ACCOUNT"] or abort("no environment variable EMAIL_RESPONDER_ACCOUNT")
EMAIL_RESPONDER_PASSWORD = ENV["EMAIL_RESPONDER_PASSWORD"] or abort("no environment variable EMAIL_RESPONDER_PASSWORD")

Mailman.config.poll_interval = 1

Mailman.config.imap = {
  server: 'imap.gmail.com', port: 993, ssl: true,
  username: EMAIL_RESPONDER_ACCOUNT,
  password: EMAIL_RESPONDER_PASSWORD,
  # filter: 'ALL'
}

Mailman::Application.run do
  from(/no[-_]*reply/) do
    ignore_mail message
  end
  from('mailer-daemon@googlemail.com') do
    ignore_mail message
  end

  default do
    begin
      name = message["From"].address_list.addresses[0].display_name
      add_to_mailchimp(name, message.from[0])
    rescue Exception => e
      Mailman.logger.error "Exception occurred while processing message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end
end
