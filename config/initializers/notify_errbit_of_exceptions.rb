exception_callback = /\/hooks\/exception_report/.freeze

Airbrake.configure do |config|
  config.api_key          = ENV["HOUSTON_ERRBIT_API_KEY"]
  config.host             = "errbit.cphepdev.com"
  config.port             = 443
  config.secure           = config.port == 443
  config.user_attributes  = %w{id email} # the default is just 'id'
  config.async            = true # requires the gem 'sucker_punch'

  # Do not report exceptions that occur when we are being
  # notified of exceptions. This can get ugly fast.
  config.ignore_by_filter do |exception_data|
    exception_data.url =~ exception_callback
  end
end

# Inform Errbit of the version of the codebase checked out
GIT_COMMIT = ENV.fetch("COMMIT_HASH", `git log -n1 --format='%H'`.chomp).freeze
module SendCommitWithNotice
  def cgi_data; (super || {}).merge("GIT_COMMIT" => GIT_COMMIT); end
end
Airbrake::Notice.send :prepend, SendCommitWithNotice
