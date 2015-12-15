source "https://rubygems.org"

gem "houston-core", github: "houston/houston-core", branch: "master"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby

gem "zendesk_api"

group :development do
  gem "letter_opener"
  gem "unicorn-rails"
  gem "spring"

  # Better error messages
  gem "better_errors"
  gem "meta_request"
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
gem "airbrake"
gem "sucker_punch" # for Airbrake
gem "skylight"

gem "star", github: "concordia-publishing-house/star", branch: "master"
gem "itsm", github: "concordia-publishing-house/itsm", branch: "master"

# Modules
gem "houston-alerts", github: "houston/houston-alerts", branch: "master"
gem "houston-brakeman", github: "houston/houston-brakeman", branch: "master"
gem "houston-dashboards", github: "concordia-publishing-house/houston-dashboards", branch: "master"
gem "houston-feedback", github: "houston/houston-feedback", branch: "master"
gem "houston-reports", github: "concordia-publishing-house/houston-reports", branch: "master"
gem "houston-roadmap", github: "houston/houston-roadmap", branch: "master"
gem "houston-scheduler", github: "houston/houston-scheduler", branch: "master"
gem "houston-slack", github: "houston/houston-slack", branch: "master"
gem "houston-support_form", github: "concordia-publishing-house/houston-support_form", branch: "master"
