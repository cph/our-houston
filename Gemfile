source "https://rubygems.org"

# Use https:// rather than git:// as the protocol for gems installed
# from GitHub. This will be the default in Bundler 2.0 and resolves
# a bug with deploying from Heroku.
# https://github.com/bundler/bundler/issues/4978#issuecomment-272248627
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "houston-core", github: "houston/houston-core", branch: "master"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby

# For talking to Office365
gem "viewpoint"

# For page-scraping
gem "mechanize"

# Bundler is a runtime dependency because it used to parse Gemfiles
gem "bundler"

# This rake dependency is being added for a CVE. This can probably be removed
# when Rails is updated.
gem "rake", "~> 12.3.0"

# LDAP for authentication
gem "devise_ldap_authenticatable", github: "cph/devise_ldap_authenticatable", branch: "master"

# for ActionCable
gem "redis", "< 4.0"

# for talking to GitHub
gem "graphql-client"

# for talking to Heroku
gem "platform-api"
gem "netrc"

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
# NB: Skylight needs to come before airbrake, as they both try to monkey patch
# net_http to observe performance, but doing it in the wrong order causes an
# infinite loop
gem "skylight"
gem "airbrake"

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


gem "star", github: "cph/star", branch: "master"

# This gem hasn't been maintained... :`(
# https://github.com/DimaSamodurov/ruby-ntlm/pull/7
# This one looks more active: https://github.com/winrb/rubyntlm
gem "ruby-ntlm", github: "macks/ruby-ntlm"


# Dependency of `houston-slack`; uncomment to develop on houston-conversations
gem "houston-conversations", github: "houston/houston-conversations", branch: "master"

# Dependency of `houston-conversations`; uncomment to develop on attentive
# gem "attentive", github: "houston/attentive", branch: "master"

# Dependency of `houston-slack`; uncomment to develop on slacks
gem "slacks", github: "houston/slacks", branch: "retry-finding-missing"

# Temporarily bump vestal_versions to unlock Rails 6
gem "houston-vestal_versions", github: "houston/vestal_versions", branch: "master"

# Modules
gem "houston-alerts", github: "houston/houston-alerts", branch: "master"
# gem "houston-brakeman", github: "houston/houston-brakeman", branch: "master"
gem "houston-ci", github: "houston/houston-ci", branch: "master"                      # Jenkins
gem "houston-commits", github: "houston/houston-commits", branch: "master"            # GitHub
gem "houston-exceptions", github: "houston/houston-exceptions", branch: "master"      # Errbit
gem "houston-feedback", github: "houston/houston-feedback", branch: "master"
gem "houston-releases", github: "houston/houston-releases", branch: "master"
gem "houston-roadmaps", github: "houston/houston-roadmaps", branch: "master"
gem "houston-scheduler", github: "houston/houston-scheduler", branch: "master"
gem "houston-slack", github: "houston/houston-slack", branch: "master"               # Slack
# gem "houston-sprints", github: "cph/houston-sprints", branch: "master"
gem "houston-tickets", github: "houston/houston-tickets", branch: "master"
gem "houston-todolists", github: "houston/houston-todolists", branch: "master"       # Todoist
gem "houston-twilio", github: "houston/houston-twilio", branch: "master"             # Twilio
gem "houston-watcher", github: "cph/houston-watcher", branch: "master"
