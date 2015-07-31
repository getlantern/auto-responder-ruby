A simple Ruby program to monitor an mail account and sends response automatically.

Make sure to DISABLE 2 step verification for your account.

```
export EMAIL_ACCOUNT=xxx
export EMAIL_PASSWORD=xxx
export MAILCHIMP_API_KEY=xxx
export MAILCHIMP_LIST_ID=xxx
export MAILCHIMP_LANG=xx  #[Full list of language codes](http://kb.mailchimp.com/lists/managing-subscribers/view-and-edit-subscriber-languages#Language-Codes)
bundle install
bundle exec ruby main.rb
```
