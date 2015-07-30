require 'mailchimp'

MAILCHIMP_API_KEY = ENV["MAILCHIMP_API_KEY"] or abort("no environment variable MAILCHIMP_API_KEY")
MAILCHIMP_LIST_ID = ENV["MAILCHIMP_LIST_ID"] or abort("no environment variable MAILCHIMP_LIST_ID")

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

