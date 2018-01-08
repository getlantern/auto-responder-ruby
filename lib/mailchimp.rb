MAILCHIMP_API_KEY = ENV["MAILCHIMP_API_KEY"] or abort("no environment variable MAILCHIMP_API_KEY")
MAILCHIMP_LIST_ID = ENV["MAILCHIMP_LIST_ID"] or abort("no environment variable MAILCHIMP_LIST_ID")
MAILCHIMP_LANG = ENV["MAILCHIMP_LANG"] or abort("no environment variable MAILCHIMP_LANG")

def add_to_mailchimp(name, addr)
  begin
    merge_vars = nil
    if name then
      fname, lname = name.split
      merge_vars = {
        'FNAME' => fname,
        'LNAME' => lname,
        'mc_language' => MAILCHIMP_LANG
      }
    end
    uri = URI("https://us2.api.mailchimp.com/3.0/lists/#{MAILCHIMP_LIST_ID}/members")
    req = Net::HTTP::Post.new(uri)
    req.basic_auth "user", MAILCHIMP_API_KEY
    req.body = {email_address: addr, email_type: 'html', status: 'subscribed', merge_fields: merge_vars}.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
      http.request(req)
    }
    if res.code == "200" then
      Mailman.logger.info "Added #{addr} to mailchimp"
    else
      error = JSON.parse(res.body)
      if error['title'] == 'Member Exists' then
        Mailman.logger.info "#{addr} is already an subscriber on mailchimp"
      else
        Mailman.logger.info "Fail to add #{addr} to mailchimp: #{error['status']} #{error['title']} - #{error['detail']}"
      end
    end
  rescue Exception => e
    Mailman.logger.info "Exception occurred while add #{addr} to mailchimp"
    Mailman.logger.info e
    for line in e.backtrace do
      Mailman.logger.info  line
    end
  end
end

