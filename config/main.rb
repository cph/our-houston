# This file loads and configures Houston

# Load Houston
require "houston/application"

# A few constants
LUKE = "luke.booth@cph.org".freeze
MATT = "matt.kobs@cph.org".freeze
ROB = "rob.riebau@cph.org".freeze
GARY = "gary.hall@cph.org".freeze
JEREMY = "jeremy.roegner@cph.org".freeze
BRAD = "brad.egberts@cph.org".freeze
KEVIN = "kevin.applegate@cph.org".freeze
DAVID = "david.bowman@cph.org".freeze
EP_DEVELOPERS = [LUKE, MATT, ROB, GARY].freeze
EP_EMPLOYEES = EP_DEVELOPERS.freeze
SS_DEVELOPERS = [KEVIN, DAVID].freeze



require_relative "../lib/slack_helpers"
require_relative "../lib/time_helpers"
require_relative "../lib/engineyard_helpers"
require_relative "../lib/misc_helpers"
require_relative "../lib/houston/engine"



Houston.register_events {{
  "github:pull:label-removed" => params("pull_request", "label").desc("A label was removed from a pull request"),
  "github:pull:label-added" => params("pull_request", "label").desc("A label was added to a pull request"),
  "staging:changed" => params("deploy", "pull_request").desc("A new pull request is on Staging"),
  "staging:updated" => params("deploy", "pull_request").desc("New commits have been deployed on Staging"),
  "staging:{project}:free" => desc("The staging environment for project {project} is free"),

  "alerts:new" => desc("An alert was added to EP's Alerts Dashboard"),
  "alerts:none" => desc("EP's Alerts Dashboard is all-clear"),

  "nanoconf:create" => params("nanoconf").desc("A nanoconf was created"),
  "nanoconf:update" => params("nanoconf").desc("A nanoconf was updated")
}}

Houston.navigation
  .add_link(:activity_feed) { Houston::Engine.routes.url_helpers.activity_feed_path }
  .name("Activity")

Houston.navigation
  .add_link(:pulls) { Houston::Engine.routes.url_helpers.pulls_path }
  .ability { can?(:read, Github::PullRequest) }

Houston.navigation
  .add_link(:nanoconfs) { Houston::Engine.routes.url_helpers.nanoconfs_path }
  .ability { can?(:read, Presentation::Nanoconf) }

Houston.add_project_column :ruby_version do
  name "Ruby"
  html { |project| project.props["keyDependency.ruby"] }
end

Houston.add_project_column :rails_version do
  name "Rails"
  html { |project| project.props["keyDependency.rails"] }
end

Houston.add_project_column :devise_version do
  name "Devise"
  html { |project| project.props["keyDependency.devise"] }
end

Houston.oauth.add_provider :office365 do
  site "https://login.microsoftonline.com"
  authorize_path "/common/oauth2/v2.0/authorize"
  token_path "/common/oauth2/v2.0/token"
end

Houston.layout["dashboard"].meta do
  stylesheet_link_tag "roboto", media: "all"
end

Houston.layout["application"].footers do
  render partial: "layouts/tester_bar"
end if ENV.fetch("RAILS_ENV", "development") == "development"




# Configure Houston
Houston.config do

  # Required
  # ---------------------------------------------------------------------------
  #
  # The path to this instance.
  # This is required so that Houston can load environment-specific
  # configuration from ./config/environments, write log files to
  # ./logs, and serve static assets from ./public.
  root Pathname.new File.expand_path("../..",  __FILE__)

  # This is the name that will be shown in the banner
  title "Houston"

  # This is the host where Houston will be running
  host "houst.in"

  # Your secret key is used for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!
  #
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  # You can use `rake secret` to generate a secure secret key.
  secret_key_base ENV["HOUSTON_SECRET_KEY_BASE"]

  # This is the email address for emails send from Houston
  mailer_sender "houston@cphepdev.com"

  # CPH allows passwords to be 7 characters
  password_length 7..128

  # Enter your Google Analytics Tracking ID to add Google's
  # Universal Analytics script to every page.
  google_analytics do
    tracking_id "UA-88832132-1"
  end

  # This is the SMTP server Houston will use to send emails
  smtp do
    authentication :plain
    address "smtp.mailgun.org"
    port 587
    domain "cphepdev.com"
    user_name ENV["HOUSTON_MAILGUN_USERNAME"]
    password ENV["HOUSTON_MAILGUN_PASSWORD"]
  end

  # These are the colors available for projects
  project_colors(
    "teal"          => "39b3aa",
    "sky"           => "239ce7",
    "sea"           => "335996",
    "indigo"        => "7d63b8",
    "thistle"       => "b35ab8",
    "chili"         => "e74c23",
    "bark"          => "756e54",
    "hazelnut"      => "a4703d",
    "burnt_sienna"  => "df8a3d",
    "orange"        => "e9b84e",
    "pea"           => "84bd37",
    "leaf"          => "409938",
    "spruce"        => "307355",
    "slate"         => "6c7a80",
    "silver"        => "a2a38b" )



  # General
  # ---------------------------------------------------------------------------
  #
  # (Optional) Sets Time.zone and configures Active Record to auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  time_zone "Central Time (US & Canada)"

  # (Optional) Parallelize requests.
  # Improves performance when Houston has to make several requests at once
  # to a remote API. Some firewalls might see this as suspicious activity.
  # In those environments, comment the following line out.
  parallelization :on

  # (Optional) Supply an S3 bucket to support file uploads
  s3 do
    access_key ENV["HOUSTON_S3_ACCESS_KEY"]
    secret ENV["HOUSTON_S3_SECRET"]
    bucket "houston-#{ENV["RAILS_ENV"] || "development"}"
  end

  # (Optional) These are the categories you can organize your projects by
  project_categories "Products", "Services", "Libraries", "Tools"



  # Navigation
  # ---------------------------------------------------------------------------
  #
  # Menus are provided by Houston and modules.
  # Additional navigation can be defined by calling
  #
  #   Houston.config.add_navigation_renderer
  #
  # For examples, see config/initializers/add_navigation_renderers.rb
  #
  # These are the menu items that will be shown in Houston
  navigation       :activity_feed,
                   :alerts,
                   :roadmaps,
                   :pulls,
                   :nanoconfs
  project_features :feedback,
                   :ideas,
                   :bugs,
                   :scheduler,
                   :goals,
                   :releases



  # Modules
  # ---------------------------------------------------------------------------
  #
  # Modules provide a way to extend Houston.
  #
  # They are mountable Rails Engines whose routes are automatically
  # added to Houston's, prefixed with the name of the module.
  #
  # To create a new module for Houston, run:
  #
  #   gem install houston-cli
  #   houston_new_module <MODULE>
  #
  # Then add the module to your Gemfile with:
  #
  #   gem "houston-<MODULE>", github: "<USERNAME>/houston-<MODULE>", branch: "master"
  #
  # Add add to this configuration file:
  #
  #   use :<MODULE> do
  #     # Module-supplied configuration options can go here
  #   end
  #
  # When developing a module, it can be helpful to tell Bundler
  # to refer to the local copy of your module's repo:
  #
  #   bundle config local.houston-<MODULE> ~/Projects/houston-<MODULE>
  #

  use :commits do
    # (Optional) Given a commit, return an array of email addresses
    # This is useful if your team uses pair-programming and attributes
    # commits to pairs by combining email addresses.
    # https://robots.thoughtbot.com/how-to-create-github-avatars-for-pairs
    identify_committers do |commit|
      emails = [commit.committer_email]
      emails = ["#{$1}@cph.org", "#{$2}@cph.org"] if commit.committer_email =~ /^pair=([a-z\.]*)\+([a-z\.]*)@/
      emails
    end
  end

  use :ci
  use :feedback
  # use :brakeman
  # use :sprints
  # use :todolists
  use :roadmaps

  use :releases do
    change_tags( {name: "New Feature", as: "feature", color: "8DB500"},
                 {name: "Improvement", as: "improvement", color: "3383A8", aliases: %w{enhancement}},
                 {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}} )
  end

  use :alerts do
    workers { User.with_email_address(EP_DEVELOPERS + SS_DEVELOPERS) }
    set_deadline do |alert|
      time_allowed = 2.days
      time_allowed = 5.days if alert.project && %w{houston errbit}.member?(alert.project.slug)
      if weekend?(alert.opened_at)
        time_allowed.after(monday_after(alert.opened_at))
      else
        deadline = time_allowed.after(alert.opened_at)
        deadline = 2.days.after(deadline) if weekend?(deadline)
        deadline
      end
    end

    sounds do
      new_alert *(10.times.map { |i| "/sounds/sword-strike-#{i}.mp3" })
      no_alerts "/sounds/get-orb.mp3"
    end
  end
  load "alerts/*"

  use :slack do
    token Rails.env.production? ? ENV["HOUSTON_SLACK_TOKEN"] : ENV["HOUSTON_DEV_SLACK_TOKEN"]
    typing_speed 120 # characters/second
  end
  load "conversations/**/*"
  load "slash_commands/*"

  use :tickets do
    ticket_types(
      "Chore"       => "909090",
      "Feature"     => "8DB500",
      "Enhancement" => "3383A8",
      "Bug"         => "C64537")
  end

  use :twilio do
    sid ENV["HOUSTON_TWILIO_SID"]
    token ENV["HOUSTON_TWILIO_TOKEN"]
    number ENV["HOUSTON_TWILIO_NUMBER"]
  end

  use :scheduler do
    planning_poker :off
    estimate_effort :off
    estimate_value :off
    mixer :off
  end

  use :watcher do
    watch :ledger, url: "https://test.360ledger.com/_status", every: "5 minutes"
  end





  # Roles and Abilities
  # ---------------------------------------------------------------------------
  #
  # A user may belong to one or more teams. Within each team, a user can be
  # given one or more team-specific roles. Define those roles — and the abilities
  # they grant below.
  #
  # Houston adds the "Team Owner" role which will be given the ability to manage
  # teams and their projects.
  #
  # Houston uses CanCan to check authorize users to do particular actions.
  # Houston will pass a user to the block defined below which should declare
  # what abilities that user has.

  load "abilities"




  # Integrations
  # ---------------------------------------------------------------------------
  #
  # Configure Houston to integrate with third-party services

  load "integrations/*"



  # Events
  # ---------------------------------------------------------------------------
  #
  # Configure Houston to execute block of code when an event is triggered.
  # To see a complete list of events run `rake houston:events` at the command line.

  load "events/**/*"



  # Timers
  # ---------------------------------------------------------------------------
  #
  # Houston can be configured to run jobs at a variety of intervals.

  load "timers/**/*"

end
