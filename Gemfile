source "https://rubygems.org"

gem "houston-core", github: "houston/houston-core", branch: "master"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby

# For talking to Office365
gem "viewpoint"

# For page-scraping
gem "mechanize"

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
gem "ruby-ntlm", github: "DimaSamodurov/ruby-ntlm", branch: "properly_resolve_ntlm_module"

# Develop on houston-conversations
gem "houston-conversations", github: "houston/houston-conversations", branch: "master"

# Develop on attentive
# gem "attentive", github: "houston/attentive", branch: "master"

# Develop on slacks
# gem "slacks", github: "houston/slacks", branch: "master"

# Modules
gem "houston-alerts", github: "houston/houston-alerts", branch: "master"
gem "houston-brakeman", github: "houston/houston-brakeman", branch: "master"
gem "houston-feedback", github: "houston/houston-feedback", branch: "master"
gem "houston-reports", github: "cph/houston-reports", branch: "master"
gem "houston-roadmaps", github: "houston/houston-roadmaps", branch: "master"
gem "houston-scheduler", github: "houston/houston-scheduler", branch: "master"
gem "houston-slack", github: "houston/houston-slack", branch: "master"
gem "houston-support_form", github: "cph/houston-support_form", branch: "master"
gem "houston-testing_report", github: "houston/houston-testing_report", branch: "master"
gem "houston-nanoconfs", github: "cph/houston-nanoconfs", branch: "master"
