A simple Ruby program to monitor an mail account on gmail.com through IMAP and send response automatically.

Make sure you DISABLED 2 step verification for the mail account.

# Run

Ruby > 2.0.0 is required

```
export EMAIL_RESPONDER_ACCOUNT=xxx
export EMAIL_RESPONDER_PASSWORD=xxx
export EMAIL_REPLIER='xxx <aaa@bbb.com>'
export MAILCHIMP_API_KEY=xxx
export MAILCHIMP_LIST_ID=xxx
export MAILCHIMP_LANG=xx  #[Full list of language codes](http://kb.mailchimp.com/lists/managing-subscribers/view-and-edit-subscriber-languages#Language-Codes)
export BODY_TEXT_URL=http://xxx
export BODY_HTML_URL=http://xxx
export ATTACHMENT_URL=http://xxx # optional
bundle install
bundle exec ruby main.rb
```
