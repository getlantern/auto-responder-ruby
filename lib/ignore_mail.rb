def ignore_mail(message)
  from = message["From"].address_list.addresses[0].raw
  subject = message["Subject"].value
  Mailman.logger.info "Skip no reply mail from #{from}: #{subject}"
rescue Exception => e
  Mailman.logger.error "Exception occurred while receiving message:\n#{message}"
  Mailman.logger.error [e, *e.backtrace].join("\n")
end
