# Configure the Errbit ErrorTracker adapter
Houston::Exceptions.config.error_tracker :errbit do
  host "errbit.cphepdev.com"
  port 443
  auth_token ENV["HOUSTON_ERRBIT_AUTH_TOKEN"]
end
