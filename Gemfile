source "https://rubygems.org"

gem "houston-core", github: "houston/houston", branch: "gem"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby

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

# Lock this at 0.6.0.
# 0.10.0 has a conflict with activerecord-insert_many
# TODO: refactor away the use of activerecord-import
# Favor activerecord-insert_many
gem "activerecord-import", "0.6.0"

# Modules
gem "houston-roadmap", github: "houston/houston-roadmap", branch: "master"
gem "houston-alerts", github: "houston/houston-alerts", branch: "master"
gem "houston-feedback", github: "houston/houston-feedback", branch: "master"
gem "houston-dashboards", github: "concordia-publishing-house/houston-dashboards", branch: "master"
gem "houston-reports", github: "concordia-publishing-house/houston-reports", branch: "master"
gem "houston-slack", github: "houston/houston-slack", branch: "master"
gem "houston-scheduler", github: "houston/houston-scheduler", branch: "master"
gem "houston-support_form", github: "concordia-publishing-house/houston-support_form", branch: "master"
