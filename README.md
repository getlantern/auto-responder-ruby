A simple Ruby program to monitor an mail account on gmail.com through IMAP and send response automatically.

Make sure you DISABLED 2 step verification for the mail account.

Gmail has limits on total mail sent per day. For production, we should use 3rd party services, say, Mandrill.

# Run

Ruby > 2.0.0 is required

You need a set of environment variables to configure it to run
```
# To check new mail via IMAP
export EMAIL_ACCOUNT=xxx
export EMAIL_PASSWORD=xxx
# To send mail using Mandrill service
export MANDRILL_API_KEY='xxx'
export REPLY_FROM_ADDR ='aaa@bbb.com'
export REPLY_FROM_NAME ='John Smith'
export BODY_TEXT_URL=http://xxx
export BODY_HTML_URL=http://xxx
export ATTACHMENT_URL=http://xxx # optional, set to attach binary in response mail
# To Add to Mailchimp list
export MAILCHIMP_API_KEY=xxx
export MAILCHIMP_LIST_ID=xxx
export MAILCHIMP_LANG=xx  #[Full list of language codes](http://kb.mailchimp.com/lists/managing-subscribers/view-and-edit-subscriber-languages#Language-Codes)

bundle install
bundle exec ruby main.rb
```
