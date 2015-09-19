Houston.config.on "hooks:mailgun_complaint" do |project, params|
  message = Mail.new
  message.from = Houston.config.mailer_sender
  message.to = %w{luke.booth@cph.org bob.lail@cph.org}
  message.subject = "Email Relay flagged as spam!"
  message.body = params.inspect
  message.delivery_method :smtp, Houston.config.smtp
  message.deliver!
end
