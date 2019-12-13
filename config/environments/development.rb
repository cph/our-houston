Rails.application.configure do
  # Settings specified here will take precedence over those in Houston.

  # Test emails
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
end
