Sentry.init do |config|
  config.environment = Rails.env
  config.breadcrumbs_logger = %i{active_support_logger}
end
