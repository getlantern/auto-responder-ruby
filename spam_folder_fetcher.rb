#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "mailman"
require_relative 'lib/ignore_mail'

Mailman.config.poll_interval = 1

Mailman.config.imap = {
  server: 'imap.gmail.com', port: 993, ssl: true,
  username: ENV['EMAIL_RESPONDER_ACCOUNT'],
  password: ENV['EMAIL_RESPONDER_PASSWORD'],
  folder: '[Gmail]/Spam',
  #filter: 'ALL'
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
      open('spam.csv', 'a') do |f|
        f.print(message["From"].address_list.addresses[0].display_name, ',', message.from[0], ',', message.date.to_s, "\n")
      end
    rescue Exception => e
      Mailman.logger.error "Exception occurred while receiving message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end
end
