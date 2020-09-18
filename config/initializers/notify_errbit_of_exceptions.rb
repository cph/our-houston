exception_callback = /\/hooks\/exception_report/.freeze

Airbrake.configure do |config|
  config.project_id       = 203
  config.project_key      = ENV["HOUSTON_ERRBIT_API_KEY"]
  config.host             = "https://errbit.cphepdev.com:443"
  config.root_directory   = Houston.root
  config.environment      = Rails.env
  config.remote_config_host = ""
  config.ignore_environments = %i{development test}
end

# Do not report exceptions that occur when we are being
# notified of exceptions. This can get ugly fast.
Airbrake.add_filter do |notice|
  notice.ignore! if notice[:url] =~ exception_callback
end

# Inform Errbit of the version of the codebase checked out
GIT_COMMIT = ENV.fetch("COMMIT_HASH", `git log -n1 --format='%H'`.chomp).freeze unless defined?(GIT_COMMIT)
Airbrake.add_filter do |notice|
  notice[:environment]["GIT_COMMIT"] = GIT_COMMIT
end

# We have to monkey-patch Airbrake::Notice, since the truncation functionality
# is intimately tied to the `to_json` method, which requires access to the
# `@payload` instance variable.
module Airbrake
  class Notice

    def to_json
      @payload.to_json
    rescue *JSON_EXCEPTIONS => ex
      @config.logger.debug("#{LOG_LABEL} `notice.to_json` failed: #{ex.class}: #{ex}")
    end

  end
end
