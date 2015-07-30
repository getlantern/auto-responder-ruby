#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "mailman"


Mailman.config.poll_interval = 1

Mailman.config.imap = {
  server: 'imap.gmail.com', port: 993, ssl: true,
  username: ENV['EMAIL_RESPONDER_ACCOUNT'],
  password: ENV['EMAIL_RESPONDER_PASSWORD'],
  filter: 'ALL'
}

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
      open('inbox.csv', 'a') do |f|
        f.print(message["From"].address_list.addresses[0].display_name, ',', message.from[0], ',', message.date.to_s, "\n")
      end
    rescue Exception => e
      Mailman.logger.error "Exception occurred while receiving message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join("\n")
    end
  end
end
