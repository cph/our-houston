source "https://rubygems.org"

gem "houston-core", github: "houston/houston-core", branch: "0.9-dev"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby

# For talking to Office365
gem "viewpoint"

# For page-scraping
gem "mechanize"

# Bundler is a runtime dependency because it used to parse Gemfiles
gem "bundler"

# LDAP for authentication
gem "houston-devise_ldap_authenticatable"

group :production do
  gem "redis"
end

group :development do
  gem "letter_opener"
  gem "puma"
  gem "spring"

  # Better error messages
  gem "better_errors"
end

group :development, :test do
  gem "pry"
end

group :test do
  gem "minitest"
  gem "capybara"
  gem "shoulda-context"
  gem "timecop"
  gem "rr"
  gem "webmock", require: "webmock/minitest"
  gem "factory_girl_rails"

  # For Jenkins
  gem "simplecov-json", require: false
  gem "minitest-reporters", require: false
  gem "minitest-reporters-turn_reporter", require: false
end

# Tooling
gem "airbrake", "~> 4.0"

# Houston is experiencing this problem:
#   github.com/brandonhilkert/sucker_punch/issues/135
# which is apparently fixed in version 2.0.
#
# However, we have to wait for Rails 5 to upgrade b/c:
#   github.com/brandonhilkert/sucker_punch/issues/156
#
# Test by setting:
#   config.development_environments = []
# and then pasting in the terminal:
#   begin; raise "test"; rescue; Airbrake.notify($!); end
gem "sucker_punch", "~> 1.6"

gem "skylight"

gem "star", github: "cph/star", branch: "master"
gem "itsm", github: "cph/itsm", branch: "master"
gem "logeater", github: "cph/logeater", branch: "master", require: "logeater/request"

# This gem hasn't been maintained... :`(
# https://github.com/DimaSamodurov/ruby-ntlm/pull/7
# This one looks more active: https://github.com/winrb/rubyntlm
gem "ruby-ntlm", github: "macks/ruby-ntlm"

# Develop on houston-conversations
gem "houston-conversations", github: "houston/houston-conversations", branch: "master"

# Develop on attentive
# gem "attentive", github: "houston/attentive", branch: "master"

# Develop on slacks
gem "slacks", ">= 0.5.0.pre", github: "houston/slacks", branch: "master"

# For deploying to EngineYard
gem "engineyard", "~> 3.2.1"

# Modules
gem "houston-alerts", github: "houston/houston-alerts", branch: "master"
gem "houston-brakeman", github: "houston/houston-brakeman", branch: "master"
gem "houston-ci", github: "houston/houston-ci", branch: "master"
gem "houston-commits", github: "houston/houston-commits", branch: "master"
gem "houston-credentials", github: "houston/houston-credentials", branch: "master"
gem "houston-exceptions", github: "houston/houston-exceptions", branch: "master"
gem "houston-feedback", github: "houston/houston-feedback", branch: "master"
gem "houston-releases", github: "houston/houston-releases", branch: "master"
gem "houston-roadmaps", github: "houston/houston-roadmaps", branch: "master"
gem "houston-scheduler", github: "houston/houston-scheduler", branch: "master"
gem "houston-slack", github: "houston/houston-slack", branch: "master"
gem "houston-sprints", github: "cph/houston-sprints", branch: "master"
gem "houston-support_form", github: "cph/houston-support_form", branch: "master"
gem "houston-tickets", github: "houston/houston-tickets", branch: "master"
gem "houston-todolists", github: "houston/houston-todolists", branch: "master"
gem "houston-twilio", github: "houston/houston-twilio", branch: "master"
