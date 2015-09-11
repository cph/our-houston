require "houston/application"

Houston.root = Pathname.new File.expand_path("../..",  __FILE__)

# Keep structure.sql in the local db directory
ActiveRecord::Tasks::DatabaseTasks.db_dir = Houston.root.join("db")

# Configure Houston
Houston::Application.paths["config/database"] = Houston.root.join("config/database.yml")
Houston::Application.paths["public"] = Houston.root.join("public")
Houston::Application.paths["log"] = Houston.root.join("log/#{Rails.env}.log")
Houston::Application.paths["tmp"] = Houston.root.join("tmp")

# TODO: finish this
Rails.application.assets = Sprockets::Environment.new(Houston.root) do |env|
  env.version = Rails.env

  path = "#{Houston.root}/tmp/cache/assets/#{Rails.env}"
  env.cache = Sprockets::Cache::FileStore.new(path)

  env.context_class.class_eval do
    include ::Sprockets::Rails::Helper
  end
end

# TODO: move to Houston to lib/patches/...
# From sprockets-rails
require 'sprockets/rails/task'
module Sprockets
  module Rails
    class Task < Rake::SprocketsTask
      
      # Backported from Sprockets 3.0.0
      def output
        if app
          # File.join(app.root, 'public', app.config.assets.prefix)
          File.join(app.paths["public"].first, app.config.assets.prefix)
        else
          super
        end
      end
    end
  end
end



Houston.config do

  # This is the name that will be shown in the banner
  title "Houston"

  # This is the host where Houston will be running
  host "status.cphepdev.com"

  # This is the email address for emails send from Houston
  mailer_sender "houston@cphepdev.com"

  # This is the passphrase Houston will use to encrypt and decrypt sensitive data
  passphrase "challenge accepted!"

  # Parallelize requests.
  # Improves performance when Houston has to make several requests at once
  # to a remote API. Some firewalls might see this as suspicious activity.
  # In those environments, comment the following line out.
  parallelization :on

  # Configuration for Email
  smtp do
    authentication :plain
    address "smtp.mailgun.org"
    port 587
    domain "cphepdev.com"
    user_name ENV["HOUSTON_MAILGUN_USERNAME"]
    password ENV["HOUSTON_MAILGUN_PASSWORD"]
  end

  # (Optional) Supply an S3 bucket to support file uploads
  s3 do
    access_key ENV["HOUSTON_S3_ACCESS_KEY"]
    secret ENV["HOUSTON_S3_SECRET"]
    bucket "houston-#{ENV["RAILS_ENV"] || "development"}"
  end

  # (Optional) These are the categories you can organize your projects by
  project_categories "Products", "Services", "Libraries", "Tools"

  # These are the colors available for projects
  project_colors(
    "teal"          => "39b3aa",
    "sky"           => "239ce7",
    "sea"           => "335996",
    "indigo"        => "7d63b8",
    "thistle"       => "b35ab8",
    "tomato"        => "e74c23",
    "bark"          => "756e54",
    "hazelnut"      => "a4703d",
    "burnt_sienna"  => "df8a3d",
    "orange"        => "e9b84e",
    "pea"           => "84bd37",
    "leaf"          => "409938",
    "spruce"        => "307355",
    "slate"         => "6c7a80",
    "silver"        => "a2a38b" )

  # (Optional) What dependencies to list on the Projects page
  key_dependencies do
    gem "rails"
    gem "devise"
  end

  # These are the tags available for each change in Release Notes
  change_tags( {name: "New Feature", as: "feature", color: "8DB500"},
               {name: "Improvement", as: "improvement", color: "3383A8", aliases: %w{enhancement}},
               {name: "Bugfix", as: "fix", color: "C64537", aliases: %w{bugfix}} )

  # These are the types of tickets
  ticket_types({
    "Chore"       => "909090",
    "Feature"     => "8DB500",
    "Enhancement" => "3383A8",
    "Bug"         => "C64537"
  })



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
  navigation       :alerts,
                   :roadmap,
                   :sprint
  project_features :support_form,
                   :feedback,
                   :ideas,
                   :bugs,
                   :scheduler,
                   :roadmap,
                   :testing,
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
  # Then add the module to this file with:
  #
  #   use :<MODULE>, github: "<USERNAME>/houston-<MODULE>", branch: "master"
  #
  # When developing a module, it can be helpful to tell Bundler
  # to refer to the local copy of your module's repo:
  #
  #   bundle config local.houston-<MODULE> ~/Projects/houston-<MODULE>
  #

  use :roadmap, github: "houston/houston-roadmap", branch: "master" do
    date "2016-09-30", "End of Members Push"
  end

  use :alerts, github: "houston/houston-alerts", branch: "master" do
    workers { User.with_email_address(FULL_TIME_DEVELOPERS) }

    sync :open, "itsm", every: "60s", first_in: "5s" do
      ITSM::Issue.open
        .map { |issue|
          project_slug, summary = issue.summary.scan(/^\s*\[([^\]]+)\]\s*(.*)$/)[0]
          text = ActionView::Base.full_sanitizer.sanitize(issue.notes) rescue issue.notes
          summary ||= issue.summary
          summary = "No summary provided" if summary.blank?
          { key: issue.key,
            number: issue.number,
            project_slug: (project_slug && project_slug.downcase),
            summary: summary,
            checked_out_by_email: issue.assigned_to_email,
            checked_out_remotely: false,
            can_change_project: true,
            requires_verification: true,
            environment_name: "production",
            text: text.strip.gsub(/\n+/, " "),
            url: issue.url
          } }
    end

    sync :all, "err", every: "75s" do
      app_project_map = Hash[Project
        .where(error_tracker_name: "Errbit")
        .pluck("cast(extended_attributes->'errbit_app_id' as integer)", :id)]

      Houston::Adapters::ErrorTracker::ErrbitAdapter \
        .all_problems(app_id: app_project_map.keys)
        .select { |problem| problem.last_notice_at > ERRBIT_BANKRUPTCY }
        .map { |problem|
          key = problem.id.to_s
          key << "-#{problem.opened_at.to_i}" if problem.opened_at >= ERRBIT_NEW_KEY_DATE
          { key: key,
            number: problem.err_ids.min,
            project_id: app_project_map[problem.app_id],
            summary: problem.message,
            environment_name: problem.environment,
            text: problem.where,
            opened_at: problem.opened_at,
            closed_at: problem.resolved_at,
            url: problem.url
          } }
    end

    sync :open, "cve", every: "5m" do
      Gemnasium::Alert.open
        .map { |alert|
          advisory = alert["advisory"]
          { key: "#{alert["project_slug"]}-#{advisory["id"]}",
            number: advisory["id"],
            project_slug: alert["project_slug"],
            summary: advisory["title"],
            environment_name: "production",
            url: "https://gemnasium.com/#{alert["project_id"]}/alerts#advisory_#{advisory["id"]}"
          } }
    end

    # sync :open, "cve", every: "5m" {
    #   Gemnasium::Alert.open.map { |alert|
    #     advisory = alert["advisory"]
    #     { key: "#{alert["project_slug"]}-#{advisory["id"]}",
    #       project_slug: alert["project_slug"],
    #       summary: advisory["title"],
    #       environment_name: "production",
    #       url: "https://gemnasium.com/#{alert["project_id"]}/alerts#advisory_#{advisory["id"]}" } } }

  end

  use :feedback, github: "houston/houston-feedback", branch: "master"

  use :dashboards, github: "concordia-publishing-house/houston-dashboards", branch: "master"

  use :reports, github: "concordia-publishing-house/houston-reports", branch: "master"

  use :slack, github: "houston/houston-slack", branch: "master" do
    token ENV["HOUSTON_SLACK_TOKEN"]
    typing_speed 120 # characters/second
    
    overhear(/\bouch\b/i) { |e| e.reply "On a scale of 1 to 10, how would you rate your pain?",
      attachments: [{
        fallback: "On a scale of 1 to 10, how would you rate your pain?",
        image_url: "http://status.cphepdev.com/extras/pain.png"
      }] }
    listen_for(/hurry up/i) { |e| e.reply "I am not fast" }
    listen_for(/fist bump/i) { |e| e.reply ":fist:", "ba da lata lata la" }
    listen_for(/^(hello|hey|hi),? @houston[\!\.]*$/i) { |e| e.reply "hello" }
    
    listen_for(/tell me when staging is free/i) do |e|
      project = Project.find_by_slug e.channel.name
      if project
        Houston.observer.once("staging:#{project.slug}:free") do
          e.reply "#{e.sender}, I think #{project.slug} staging might be free now"
        end
        e.reply "No problem"
      else
        e.reply "Sorry. I can only do that if you ask me in a project channel :confused:"
      end
    end
    
    listen_for(/what.* on staging\?/i) do |e|
      pulls = Houston.github.org_issues(Houston.config.github[:organization], labels: "on-staging", filter: "all")
      e.reply "There are no pull requests on Staging" if pulls.none?
      e.reply pulls.map { |pr| "For *#{pr.repository.name}*, #{slack_link_to_pull_request(pr)} is on Staging" }
    end
    
    # A complete regex looks like this: http://stackoverflow.com/a/12093994/731300
    listen_for(/deploy.*\s(?:\#?(?<number>\d+)\b|(?<branch>[\w\d\+\-\._\/]+))/i) do |e|
      target = "number" if e.matched? :number
      target = "branch" if e.matched? :branch
      user = User.find_by_email_address(e.sender.email)
      
      unless user
        e.reply "I'm sorry. I don't know who you are."
        next
      end
      
      unless user.developer?
        e.reply "I'm sorry. You have to be a developer to deploy a pull request"
        next
      end
      
      Houston.tdl.add(
        user: user,
        goal: "deploy",
        describe: "I am deploying #{e.match[target]}",
        step: "find-pr",
        conversation: e.start_conversation!,
        target: { type: target, value: e.match[target] })
    end
    
    listen_for(/what are you (?:doing|working on)\?/) do |e|
      e.reply "Nothing" if Houston.tdl.empty?
      e.reply Houston.tdl.map(&:describe)
    end
  end

  use :scheduler, github: "houston/houston-scheduler", branch: "master" do
    planning_poker :off
    estimate_effort :off
    estimate_value :off
    mixer :off
  end

  use :support_form, github: "concordia-publishing-house/houston-support_form", branch: "master"

  gem "star", github: "concordia-publishing-house/star", branch: "master"
  gem "itsm", github: "concordia-publishing-house/itsm", branch: "master"



  # Roles
  # ---------------------------------------------------------------------------
  #
  # A user can have zero or one of these roles.
  # You can refer to these roles when you configure
  # abilities.
  #
  # To this list, Houston will add the role "Guest",
  # which is the default (null) role.
  #
  # Presently, Houston requires that "Tester" be
  # one of these roles.
  roles "Developer",
        "Tester"

  # Project Roles
  # ---------------------------------------------------------------------------
  #
  # Each of these roles is project-specific. A user
  # can have zero or many project roles. You can refer
  # to these roles when you configure abilities.
  #
  # Presently, Houston requires that "Maintainer" be
  # one of these roles.
  project_roles "Owner",
                "Maintainer"

  # Abilities
  # ---------------------------------------------------------------------------
  #
  # In this block, use the DSL defined by CanCan.
  # Learn more: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  abilities do |user|
    if user.nil?

      # Customers are allowed to see Release Notes of products, for production
      can :read, Release do |release|
        release.project.category == "Products" && (release.environment_name.blank? || release.environment_name == "production")
      end

      # Customers are allowed to see Features, Improvements, and Bugfixes
      can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

    else

      # Everyone can see Releases to staging
      can :read, Release

      # Everyone is allowed to see Features, Improvements, and Bugfixes
      can :read, ReleaseChange, tag_slug: %w{feature improvement fix}

      # Everyone can see Projects
      can :read, Project

      # Everyone can see Tickets
      can :read, Ticket

      # Everyone can see Milestones
      can :read, Milestone

      # Everyone can see Users and update themselves
      can :read, User
      can :update, user

      # Everyone can make themselves a "Follower"
      can :create, Role, name: "Follower"

      # Everyone can remove themselves from a role
      can :destroy, Role, user_id: user.id

      # Everyone can edit their own testing notes
      can [:update, :destroy], TestingNote, user_id: user.id

      # Everyone can see project quotas
      can :read, Houston::Scheduler::ProjectQuota

      # Everyone can read and tag and create feedback
      can :read, Houston::Feedback::Comment
      can :tag, Houston::Feedback::Comment
      can :create, Houston::Feedback::Comment

      # Everyone can update their own feedback
      can [:update, :destroy], Houston::Feedback::Comment, user_id: user.id

      # Developers can
      #  - create tickets
      #  - see other kinds of Release Changes (like Refactors)
      #  - update Sprints
      #  - change Milestones' tickets
      #  - break tickets into tasks
      if user.developer?
        can :read, [Commit, ReleaseChange]
        can :manage, Sprint
        can :update_tickets, Milestone
        can :manage, Task
      end

      # Testers and Developers can
      #  - see and comment on all testing notes
      #  - create tickets
      #  - see and manage alerts
      if user.tester? or user.developer?
        can :create, Ticket
        can [:create, :read], TestingNote
        can :manage, Houston::Alerts::Alert
      end

      # The following abilities are project-specific and depend on one's role
      roles = user.roles.participants
      if roles.any?

        # Everyone can see and comment on Testing Reports for projects they are involved in
        can [:create, :read], TestingNote, project_id: roles.pluck(:project_id)

        # Maintainers can manage Releases, close and estimate Tickets, and update Projects
        roles.maintainers.pluck(:project_id).tap do |project_ids|
          can :manage, Release, project_id: project_ids
          can :update, Project, id: project_ids
          can :close, Ticket, project_id: project_ids
          can :estimate, Project, id: project_ids # <-- !todo: remove
        end

        # Product Owners can prioritize tickets
        can :prioritize, Project, id: roles.owners.pluck(:project_id)
      end
    end
  end



  # Integrations
  # ---------------------------------------------------------------------------
  #
  # Configure Houston to integrate with third-party services

  # (Optional) Utilize an alternate Devise Authentication Strategy
  authentication_strategy :ldap do
    # host "10.5.3.100"
    # port 636
    # ssl :simple_tls
    host "172.31.1.253"
    port 389
    base "dc=cph, dc=pri"
    username_builder Proc.new { |attribute, login, ldap| "#{login}@cph.pri" }
  end

  engineyard do
    api_token ENV["HOUSTON_ENGINEYARD_API_TOKEN"]
  end

  # Configure the Unfuddle TicketTracker adapter
  ticket_tracker :unfuddle do
    subdomain "cphep"
    username ENV["HOUSTON_UNFUDDLE_USERNAME"]
    password ENV["HOUSTON_UNFUDDLE_PASSWORD"]

    identify_tags lambda { |ticket|
      tags = []
      tags << TICKET_TAGS_FOR_UNFUDDLE[ticket.severity]
      tags << TicketTag.new(ticket.component, "404040") unless ticket.component.blank?
      tags.compact
    }

    identify_type lambda { |ticket|
      case ticket.severity
      when "0 Suggestion" then ticket.summary =~ /New Feature/ ? "Feature" : "Enhancement"
      when "Feature", "Bug", "Chore", "Enhancement" then ticket.severity
      else "Enhancement"
      end
    }

    attributes_from_type lambda { |type|
      severity = type
      severity = "Enhancement" if severity == "Tweak"
      {severity: severity}
    }
  end

  # Configure the Github Issues TicketTracker adapter
  ticket_tracker :github do
    identify_type lambda { |ticket|
      labels = Array(ticket.raw_attributes["labels"]).map { |label| label["name"].downcase }
      return "Bug"      if (labels & %w{bug}).any?
      return "Feature"  if (labels & %w{feature}).any?
      return "Enhancement" if (labels & %w{enhancement tweak}).any?
      return "Chore"    if (labels & %w{chore refactor}).any?
      "Enhancement"
    }

    attributes_from_type lambda { |type|
      case type
      when "Enhancement" then {labels: ["enhancement"]}
      when "Bug" then {labels: ["bug"]}
      when "Feature" then {labels: ["feature"]}
      when "Chore" then {labels: ["chore"]}
      else {}
      end
    }

    identify_tags lambda { |ticket|
      Array(ticket.raw_attributes["labels"]) \
        .select { |label| !%w{bug feature enhancement refactor chore}.member?(label["name"].downcase) } \
        .map { |label| TicketTag.new(label["name"], label["color"]) }
    }
  end

  # Configure the Jenkins CIServer adapter
  ci_server :jenkins do
    host "ci.cphepdev.com"
    port 443
    username ENV["HOUSTON_JENKINS_USERNAME"]
    password ENV["HOUSTON_JENKINS_PASSWORD"]
  end

  # Configure the Errbit ErrorTracker adapter
  error_tracker :errbit do
    host "errbit.cphepdev.com"
    port 443
    auth_token ENV["HOUSTON_ERRBIT_AUTH_TOKEN"]
  end

  # Configuration for GitHub
  # Use the following command to generate an access_token
  # for your GitHub account to allow Houston to modify
  # commit statuses.
  #
  # curl -v -u USERNAME -X POST https://api.github.com/authorizations --data '{"scopes":["repo:status"]}'
  #
  github do
    # Access token for houstonbot with scopes: ["repo"]
    access_token ENV["HOUSTON_GITHUB_ACCESS_TOKEN"]
    key ENV["HOUSTON_GITHUB_KEY"]
    secret ENV["HOUSTON_GITHUB_SECRET"]
    organization "concordia-publishing-house"
  end

  # Configuration for Gemnasium
  gemnasium do
    api_key ENV["HOUSTON_GEMNASIUM_API_KEY"]
  end



  # Events
  # ---------------------------------------------------------------------------
  #
  # Attach a block to handle any of the events broadcast by
  # Houston's event system:
  #   * antecedent:*:released   When a Ticket has been released, for each antecedent
  #   * antecedent:*:resolved   When a Ticket has been resolved, for each antecedent
  #   * antecedent:*:closed     When a Ticket has been closed, for each antecedent
  #   * boot                    When the Rails application is booted
  #   * daemon:*:start          When a background thread (like the Scheduler or Slack) starts
  #   * daemon:*:restart        When a background thread (like the Scheduler or Slack) is restarted
  #   * daemon:*:stop           When a background thread (like the Scheduler or Slack) dies
  #   * deploy:completed        When a deploy has been recorded
  #   * hooks:*                 When a Web Hook as been triggered
  #   * release:create          When a new Release has been created
  #   * test_run:start          When the CI server has begun a build
  #   * test_run:complete       When the CI server has completed a build
  #   * testing_note:create     When a Testing Note has been created
  #   * testing_note:update     When a Testing Note has been updated
  #   * testing_note:save       When a Testing Note has been created or updated
  #   * ticket:release          When a Ticket is mentioned in a Release
  #   * task:released           When a commit mentioning a Task is released
  #   * task:committed          When a commit mentioning a Task is pushed
  #   * task:completed          When a Task is marked completed
  #   * task:reopened           When a Task is marked reopened
  #   * alert:create            When an Alert is created
  #   * alert:*:create          When an Alert of a particular type is created
  #   * alert:assign            When an Alert is assigned
  #   * alert:*:assign          When an Alert of a particular type is assigned
  #   * alert:deployed          When an Alert is deployed
  #   * alert:*:deployed        When an Alert of a particular type is deployed

  on "boot" do
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
  end



  on "tdl:deploy.find-pr" do |task|
    target = task.target
    
    pulls = %w{members unite ledger}.flat_map { |repo| \
      Houston.github.pulls([Houston.config.github[:organization], "/", repo].join) }
    pulls.select! { |pr| pr.number == target.value.to_i } if target.type == "number"
    pulls.select! { |pr| pr.head.ref == target.value } if target.type == "branch"
    
    case pulls.length
    when 0
      if target.type == "branch"
        task.set! step: "find-branch"
      else
        task.end! "Hm. I couldn't find an open pull request with the #{target.type} #{target.value}..."
      end
    when 1
      pr = pulls[0]
      task.set! pr: pr, project: Project.find_by_slug(pr.base.repo.name), step: "strategy?"
    else
      repos = pulls.map { |pr| pr.base.repo.name }
      repo = /(?<repo>#{Regexp.union(repos)})/i
      
      task.advise "I'm waiting to hear which pull request I should deploy"
      task.conversation.ask "#{repos.map { |name| "*#{name}*" }.to_sentence} #{repos.length == 2 ? "both" : "all"} have pull requests with the #{target.type} *#{target.value}*. Which one should I deploy?", expect: repo do |e|
        pr = pulls.detect { |pr| pr.base.repo.name == e.match[:repo] }
        task.set! pr: pr, project: Project.find_by_slug(pr.base.repo.name), step: "strategy?"
      end
    end
  end

  on "tdl:deploy.find-branch" do |task|
    branch = task.target.value
    
    repos = %w{members unite ledger}.select { |repo|
      begin
        Houston.github
          .refs("#{Houston.config.github[:organization]}/#{repo}", "heads/#{branch.chop}")
          .select { |ref| ref.ref == "refs/heads/#{branch}" }
          .any?
      rescue Octokit::NotFound
        false
      end }
    
    case repos.length
    when 0
      task.end! "I couldn't find a branch named *#{branch}*. Is that spelling right?"
    when 1
      task.set! project: Project.find_by_slug(repos[0]), step: "create-pr"
    else
      repo = /(?<repo>#{Regexp.union(repos)})/i
      
      task.advise "I'm waiting to hear which branch I should deploy"
      task.conversation.ask "#{repos.map { |name| "*#{name}*" }.to_sentence} #{repos.length == 2 ? "both" : "all"} have branches named *#{branch}*. Which one should I deploy?", expect: repo do |e|
        task.set! project: Project.find_by_slug(e.match[:repo]), step: "create-pr"
      end
    end
  end

  on "tdl:deploy.create-pr" do |task|
    project = task.project
    branch = task.target.value
    repo = project.repo
    
    # !todo: the pull request could've been created in the meantime...
    begin
      pr = repo.create_pull_request(base: "master", head: branch, title: branch.titleize)
      repo.add_labels_to %w{review-needed test-needed}, pr.number

      task.conversation.reply "I created a pull request for that branch, #{slack_link_to_pull_request(pr)}. Would you add testing instructions?"
      task.set! pr: pr, step: "strategy?"
    rescue Octokit::UnprocessableEntity
      task.end! "Sorry, I couldn't find a pull request for the branch *#{branch}* and I got an error when trying to create one. :disappointed:"
    end
  end

  # !todo: strictly, all of the following should be atomic
  on "tdl:deploy.strategy?" do |task|
    other_deploys = Houston.tdl.where(goal: "deploy")
      .reject { |other| other == task }
      .select { |other| other.project && other.project.id == task.project.id }
    
    if deploy_by_other_user = other_deploys.find { |deploy| deploy.user != task.user }
      task.conversation.reply "I'm sorry. #{deploy_by_other_user.user.first_name} is deploying #{slack_link_to_pull_request deploy_by_other_user.pr} right now."
      next
    end
    
    if deploy_executing = other_deploys.find { |deploy| deploy.step == "execute" }
      task.conversation.reply "I'm sorry. #{slack_link_to_pull_request deploy_executing.pr} is being deployed right now."
      next
    end
    
    other_deploys.each(&:cancel!)
    task.conversation.reply "ok"
    
    # !todo: support other strategies
    # we're just deploying members, unite, and ledger to Staging for now,
    # so we can assume that the strategy is Engineyard
    task.set! environment: Houston::Adapters::Deployment::Engineyard.new(task.project, "staging"),
              step: "on-staging?"
  end

  YESORNO = /(?<affirmative>yes|ok|sure|yeah|ya)|(?<negative>no)/i.freeze
  ACKNOWLEDGEMENT = ["Alright, thanks.", "OK", "got it", "ok", "ok"].freeze

  on "tdl:deploy.on-staging?" do |task|
    other_pr = Houston.github.list_issues("#{Houston.config.github[:organization]}/#{task.project.slug}", labels: "on-staging", filter: "all")
      .select(&:pull_request)
      .reject { |pr| pr.number == task.pr.number }
      .reject { |pr| pr.labels.any? { |label| label.name == "test-complete" } }
      .first

    if other_pr
      # !todo: this could be cached
      user = User.find_by_email_address Houston.github.user(other_pr.user.login).email
      task.advise "I'm waiting to hear if I can have staging"
      task.conversation.ask "#{user == task.user ? "You have" : "#{user ? user.first_name : other_pr.user.login} has"} #{slack_link_to_pull_request(other_pr)} on staging. Is it OK for me to deploy #{task.target.value}?", expect: YESORNO do |e|
        if e.matched?(:affirmative)
          task.set! step: "maintenance-page?"
        else
          task.end! "ok. I won't deploy it."
        end
      end
    else
      task.set! step: "maintenance-page?"
    end
  end
  
  # !todo: connect to the database and figure out which migrations will actually run
  on "tdl:deploy.maintenance-page?" do |task|
    migrations = task.project.repo
      .changes(task.environment.last_deploy_commit, task.pr.head.sha)
      .grep(/^db\/migrate\//)
    
    added = migrations.select(&:added?)
    modified = migrations.select(&:modified?)
    deleted = migrations.select(&:deleted?)
    
    summary = []
    summary << "1 migration was added:" if added.length == 1
    summary << "#{added.length} migrations were added:" if added.length > 1
    summary << ("\n```\n" << added.map { |change| change.file[11..-1] }.join("\n") << "\n```\n") if added.length > 0
    
    summary << "Also, " if added.length > 0 and (modified.length > 0 or deleted.length > 0)
    summary << "1#{" migration" if added.none?} was modified:" if modified.length == 1
    summary << "#{modified.length}#{" migrations" if added.none?} were modified:" if modified.length > 1
    summary << "\n```\n#{modified.map { |change| change.file[11..-1] }.join("\n")}```\n" if modified.length > 0
    
    summary << "And " if modified.length > 0 and deleted.length > 0
    summary << "1#{" migration" if added.none? && modified.none?} was deleted:" if deleted.length == 1
    summary << "#{deleted.length}#{" migrations" if added.none? && modified.none?} were deleted:" if deleted.length > 1
    summary << "\n```\n#{deleted.map { |change| change.file[11..-1] }.join("\n")}```\n" if deleted.length > 0
    
    summary = summary.join(" ")
    if added.any? || modified.any?
      task.advise "I'm waiting to hear if I should use the maintenance page"
      task.conversation.ask "It looks like #{summary}\nShould I put the maintenance page up?", expect: YESORNO do |e|
        task.set! step: "execute", maintenance_page: e.matched?(:affirmative)
        e.reply ACKNOWLEDGEMENT.sample
      end
      
      task.conversation.say "(I'd recommend putting the maintenance page up if the old version of #{task.project.slug} will break on the new schema.)"
    else
      task.set! step: "execute", maintenance_page: false
    end
  end

  # deploy = Deploy.find(3255)
  # environment = Houston::Adapters::Deployment::Engineyard.new(deploy.project, "staging")
  # deploy.update_column :completed_at, nil
  # environment.deploy(deploy, maintenance_page: false)
  on "tdl:deploy.execute" do |task|
    # Fork so that if Houston dies, this process sticks around until the Deploy is complete
    # task.advise and task.end! don't
    # fork do
      deploy = Deploy.create!(
        project: task.project,
        environment_name: "staging",
        sha: task.pr.head.sha,
        branch: task.pr.head.ref,
        deployer: task.user.email)
      deploy_url = Rails.application.routes.url_helpers.project_deploy_url({project_id: task.project.slug, id: deploy.id}.merge(Rails.configuration.action_mailer.default_url_options))
      
      task.advise "It started at #{deploy.created_at.strftime("%b %e, %l:%M %p")}."
      task.conversation.say "I am deploying #{slack_link_to_pull_request(task.pr)}"
      task.conversation.say "You can follow my progress #{slack_link_to "here", deploy_url}"
      
      begin
        if task.environment.deploy(deploy, maintenance_page: task.maintenance_page)
          task.end! "I have finished deploying #{task.target.value} (#{slack_link_to "output", deploy_url})"
        else
          task.end! ":rotating_light: #{task.user.first_name}, the deploy of #{task.target.value} just failed. (#{slack_link_to "output", deploy_url})"
        end
      rescue EY::CloudClient::RequestFailed
        Houston.report_exception $!
        task.end! ":rotating_light: I'm sorry. An error occurred: #{$!.message}"
      end
    # end
  end



  on "hooks:mailgun_complaint" do |project, params|
    message = Mail.new
    message.from = Houston.config.mailer_sender
    message.to = %w{luke.booth@cph.org bob.lail@cph.org}
    message.subject = "Email Relay flagged as spam!"
    message.body = params.inspect
    message.delivery_method :smtp, Houston.config.smtp
    message.deliver!
  end

  on "task:committed" do |task|
    # Treat tasks as completed when a commit mentioning them is pushed
    task.completed!
  end



  # Notify me if any of the daemons is misbehaving

  on "daemon:scheduler:restart" do
    slack_send_message_to "The thread running Rufus::Scheduler errored out and is attempting to recover", "@boblail"
  end

  on "daemon:scheduler:stop" do
    slack_send_message_to ":rotating_light: The thread running Rufus::Scheduler has terminated", "@boblail"
  end

  on "daemon:slack:restart" do
    slack_send_message_to "The thread running Slack errored out and is attempting to recover", "@boblail"
  end

  on "daemon:slack:stop" do
    slack_send_message_to ":rotating_light: The thread running Slack has terminated", "@boblail"
  end

  on "slack:error" do |args|
    slack_send_message_to "An error occurred\n#{args.inspect}", "@boblail"
  end



  on "test_run:complete" do |test_run|
    # When branch is nil, the test run was requested by Houston
    # not triggered by a developer pushing changes to GitHub.
    next if test_run.branch.nil?
    next if test_run.aborted?

    nickname = SLACK_USERNAME_FOR_USER[test_run.user.email] if test_run.user
    project_slug = test_run.project.slug
    project_channel = "##{project_slug}"
    branch = "#{project_slug}/#{test_run.branch}"

    text = test_run.short_description(with_duration: true)
    text << "\n#{nickname}" if test_run.result != "pass" && nickname

    attachment = case test_run.result
    when "pass"
      { color: "#5DB64C",
        title: "All tests passed on #{branch}" }
    when "fail"
      { color: "#E24E32",
        title: "#{test_run.fail_count} #{test_run.fail_count == 1 ? "test" : "tests"} failed on #{branch}" }
    else
      { color: "#DFCC3D",
        title: "The tests are broken on #{branch}" }
    end
    attachment.merge!(
      title_link: test_run.url,
      fallback: attachment[:title],
      text: text)

    channel = project_channel if Houston::Slack.connection.channels.include? project_channel
    channel ||= nickname
    channel ||= "developers"

    slack_send_message_to nil, channel, attachments: [attachment]
  end

  on "test_run:compared" do |test_run|
    regressions = test_run.test_results.where(different: true, status: "fail").to_a
    next if regressions.none?

    commit = slack_link_to(test_run.sha[0...7], test_run.commit.url)
    predicate = "this test:" if regressions.count == 1
    predicate = "these tests:" if regressions.count > 1 && regressions.count < 5
    predicate = "#{regressions.count} tests" if regressions.count > 5
    predicate = slack_link_to(predicate, test_run.url)

    message = "Hey... I think this commit :point_right: *#{commit}* broke #{predicate}"

    regressions.each do |regression|
      message << "\n> *#{regression.test.suite}* #{regression.test.name}"
    end if regressions.count < 5

    project_channel = "##{test_run.project.slug}"
    channels = [project_channel] if Houston::Slack.connection.channels.include? project_channel
    channels ||= test_run.commit.committers
      .pluck(:email)
      .map { |email| SLACK_USERNAME_FOR_USER[email] }
      .reject(&:nil?)
    channels = %w{developers} if Array(channel).empty?

    channels.each do |channel|
      slack_send_message_to message, channel
    end
  end



  on "alert:assign" do |alert|
    if alert.checked_out_by && alert.updated_by && alert.checked_out_by != alert.updated_by
      Rails.logger.info "\e[34m[slack] #{alert.type} assigned to \e[1m#{alert.checked_out_by.first_name}\e[0m"
      
      case (rand * 100).to_i
      when 0..3
        message = ":bomb:"
      when 4..25
        message = "#{alert.updated_by.first_name} threw you under the bus"
      when 26..70
        message = "#{alert.checked_out_by.first_name}, #{alert.updated_by.first_name} assigned you this *#{alert.type}*"
        message << " for #{alert.project.slug}" if alert.project
      else
        message = "#{alert.checked_out_by.first_name}, #{alert.updated_by.first_name} assigned this *#{alert.type}*"
        message << " for #{alert.project.slug}" if alert.project
        message << " to you"
      end
      
      slack_send_message_to message, alert.checked_out_by, attachments: [slack_alert_attachment(alert)]
    end
  end

  # Notify ITSM of change of assignment
  on "alert:itsm:assign" do |alert|
    itsm = ITSM::Issue.find alert.number
    itsm.assign_to! alert.checked_out_by || "Emerging Products" if itsm
  end

  # Notify #alerts of new alerts
  on "alert:create" do |alert|
    message =  "There's a new *#{alert.type}*"
    message << " for #{alert.project.slug}" if alert.project
    slack_send_message_to message, "#alerts", attachments: [slack_alert_attachment(alert)]
  end



  on "testing_note:create" do |note|
    ticket, verdict = note.ticket, note.verdict
    ProjectNotification.testing_note(note, ticket.participants).deliver! if verdict == "none"
    ProjectNotification.testing_note(note, ticket.participants.reject(&:tester?)).deliver! if verdict == "fails"
  end



  on "deploy:completed" do |deploy|
    next if deploy.build_release.ignore?

    deployer = deploy.user
    if deployer
      message = "#{deployer.first_name}, your deploy of #{deploy.project.slug} " <<
                "to #{deploy.environment_name} just finished. " <<
                slack_link_to("Click here to write release notes",
                  Rails.application.routes.url_helpers.new_release_url(
                    deploy.project.to_param,
                    deploy.environment_name,
                    host: Houston.config.host,
                    deploy_id: deploy.id,
                    auth_token: deployer.authentication_token))
      slack_send_message_to message, deployer
    end

    Houston.try({max_tries: 3}, Net::OpenTimeout) do
      DeployNotification.new(deploy).deliver! # <-- after extracting releases, move this to Releases
    end
  end

  on "deploy:completed" do |deploy|
    project = deploy.project
    if deploy.environment == "staging" && deploy.branch && project.on_github?
      pr_deployed = project.repo.pull_requests.find { |pr| pr.head.ref == deploy.branch }
      if pr_deployed
        on_staging = project.repo.issues(labels: "on-staging").map(&:number)
        on_staging.each do |pr_number|
          project.repo.remove_label_from("on-staging", pr_number) unless pr_number == pr_deployed.number
        end
        if on_staging.member?(pr_deployed.number)
          Houston.observer.fire "staging:updated", deploy, pr_deployed
        else
          project.repo.add_label_to "on-staging", pr_deployed
          Houston.observer.fire "staging:changed", deploy, pr_deployed
        end
      end
    end
  end

  on "staging:changed" do |deploy, pr|
    slack_send_message_to ":star2: The Pull Request #{slack_link_to_pull_request(pr)} is now on *#{deploy.project.slug}* Staging", "#testers"
  end

  on "staging:updated" do |deploy, pr|
    slack_send_message_to "New commits have been deployed for #{slack_link_to_pull_request(pr)} on *#{deploy.project.slug}* Staging", "#testers"
  end

  on "alert:deployed" do |alert, deploy, commit|
    next if alert.checked_out_by
    next unless committer = commit.committers.first
    alert.update_attribute :checked_out_by, committer
  end

  on "alert:err:deployed" do |alert, deploy, commit|
    project = deploy.project
    error_tracker = project.error_tracker
    repo = project.repo

    message = "Resolved by Houston when #{commit.sha} was deployed to #{deploy.environment_name}"
    message << "\n#{repo.commit_url(commit.sha)}" if repo.respond_to?(:commit_url)

    Houston.try({max_tries: 3, ignore: true}, Faraday::Error::TimeoutError) do
      error_tracker.resolve! alert.number, message: message
    end
  end

  on "alert:itsm:deployed" do |alert, deploy, commit|
    user = alert.checked_out_by
    addressee, channel = user ? [user.first_name, user]: ["@group", "developers"]

    message = [
      "Hey #{addressee},",
      slack_link_to(commit.sha[0...7], commit.url),
      "was just deployed to #{deploy.environment_name}.",
      "Does that close this ITSM?" ].join(" ")
    slack_send_message_to message, channel,
      attachments: [slack_alert_attachment(alert)]
  end



  on "github:pull:updated" do |pull_request, changes|
    next unless changes.key? "labels"
    before, after = changes["labels"]
    before = before.split("\n")

    removed = before - after
    added = after - before
    if (before.include?("on-staging") && added.include?("test-pass")) || removed.include?("on-staging")
      Houston.observer.fire "staging:#{pull_request.project.slug}:free"
    end
  end



  on "github:comment:commit" do |comment|
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["commit_id"][0...7], url)}"

    comment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [comment], test: true
  end

  on "github:comment:diff" do |comment|
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["path"], url)}"
    message << "\n```\n#{comment["diff_hunk"]}\n```\n"

    comment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [comment], test: true
  end

  on "github:comment:pull" do |comment|
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    issue = comment["issue"]
    message = "#{comment["user"]["login"]} commented on #{slack_link_to("##{issue["number"]} #{issue["title"]}", url)}"

    comment = { fallback: body, text: body }
    slack_send_message_to message, channel, as: :github, attachments: [comment], test: true
  end



  # Background Jobs
  # ---------------------------------------------------------------------------
  #
  # Houston can be configured to run jobs at a variety of intervals.

  every "6h", "sync:tickets" do
    SyncAllTicketsJob.run!
  end

  at "2:00am", "sync:commits" do
    SyncCommitsJob.run!
  end

  every "10m", "sync:pulls" do
    Github::PullRequest.sync!
  end

  at "6:40am", "report:alerts", every: :weekday do
    Houston.try({max_tries: 3}, Net::OpenTimeout) do
      Houston::Alerts::Mailer.deliver_to!(FULL_TIME_DEVELOPERS) unless Rails.env.development?
    end
  end

  at "3:00pm", "remind:startime:thursday", every: :thursday do
    slack_send_message_to "Hey @everyone, don't forget to get your Star time and Unitime this afternoon!", "#general"
  end

  at "12:00pm", "remind:startime", every: :weekday do
    today = Date.today
    first_of_month = today.beginning_of_month
    yesterday = today - 1
    
    date_range = first_of_month..yesterday
    dates_expected = date_range.select { |date| (1..5).include?(date.wday) }
    next if dates_expected.empty?
    
    FULL_TIME_DEVELOPERS.each do |email|
      user = User.find_by_email_address(email)
      next unless user
      
      records = get_time_records_for(user, during: date_range)
      dates_missing_empower = dates_expected & records.select { |time| time[:off] < 8 && time[:worked].zero? }.map { |time| time[:date] }
      dates_missing_star = dates_expected & records.select { |time| time[:off] < 8 && time[:charged].zero? }.map { |time| time[:date] }
      next if dates_missing_empower.none? && dates_missing_star.none?
      
      dates_missing_both = dates_missing_empower & dates_missing_star
      dates_missing_empower_only =  dates_missing_empower - dates_missing_both
      dates_missing_star_only = dates_missing_star - dates_missing_both
      
      message = "#{user.first_name}, don't forget to put in "
      
      format_dates = lambda do |dates|
        dates.map { |date|
          days_ago = today - date
          if days_ago == 1
            "yesterday"
          elsif days_ago <= 7
            if date.beginning_of_week < today.beginning_of_week
              "last " << date.strftime("%A")
            else
              date.strftime("%A")
            end
          else
            date.strftime("%b %-d")
          end
        }.to_sentence
      end
      
      if dates_missing_empower_only.none? && dates_missing_star_only.none?
        message << "your time (Star & Empower) for #{format_dates.(dates_missing_both)}"
      elsif dates_missing_both.any? && dates_missing_empower_only.any? && dates_missing_star_only.any?
        message << "your Star time for #{format_dates.(dates_missing_star_only)}, "
        message << "your Empower time for #{format_dates.(dates_missing_empower_only)}, and "
        message << "both for #{format_dates.(dates_missing_both)}"
      else
        missing = []
        missing << "your Star time for #{format_dates.(dates_missing_star_only)}" if dates_missing_star_only.any?
        missing << "your Empower time for #{format_dates.(dates_missing_empower_only)}" if dates_missing_empower_only.any?
        missing << "both your Star and Empower time for #{format_dates.(dates_missing_both)}" if dates_missing_both.any?
        message << missing.to_sentence
      end
      
      slack_send_message_to message, user, test: true
    end
  end

  at "11:50pm", "take:measurements", every: :thursday do
    measure_sprint_effort_for_week!
    measure_alerts_for_week!
  end

  at "6:00am", "report:weekly:developer", every: :friday do
    date = Date.today - 1
    User.with_email_address(FULL_TIME_DEVELOPERS).each do |user|
      report = Houston::Reports::WeeklyUserReport.new(user, date)
      Houston.try({max_tries: 3}, Net::OpenTimeout) do
        Houston::Reports::Mailer.weekly_user_report(report, bcc: "bob.lail@cph.org").deliver!
      end
    end
  end

  at "3:35pm", "report:feedback:daily.digest" do
    User.with_view_option("feedback.digest", "daily").find_each do |user|
      comments = Houston::Feedback::Comment
        .where(project_id: user.followed_projects.pluck(:id))
        .unread_by(user)
        .since(1.day.ago)
      Houston.try({max_tries: 3}, Net::OpenTimeout) do
        Houston::Feedback::Mailer.daily_digest_for(comments, user).deliver! if comments.any?
      end
    end
  end

  at "3:35pm", "report:feedback:weekly.digest", every: :friday do
    User.with_view_option("feedback.digest", "weekly").find_each do |user|
      comments = Houston::Feedback::Comment
        .where(project_id: user.followed_projects.pluck(:id))
        .unread_by(user)
        .since(1.week.ago)
      Houston.try({max_tries: 3}, Net::OpenTimeout) do
        Houston::Feedback::Mailer.weekly_digest_for(comments, user).deliver! if comments.any?
      end
    end
  end

  at "6:30pm", "repo:prune", every: :sunday do
    %w{members unite ledger}.each do |project_slug|
      project = Project.find_by_slug(project_slug)
      
      # Don't delete certain required branches
      # or any branch which is the head or target
      # of an open pull request.
      protected_branches = %w{master beta dev}.to_set
      project.repo.pull_requests.each do |pr|
        protected_branches.add(pr.head.ref).add(pr.base.ref)
      end
      
      branches = project.repo.branches.keys - protected_branches.to_a
      if branches.any?
        Rails.logger.info "\e[34m[repo:prune] Deleting \e[1m#{branches.length}\e[0;34m branches from \e[1m#{project_slug}\e[0m"
      
        started_at = Time.now
        deleted_refs = branches.map { |branch| ":refs/heads/#{branch}" }
        credentials = Houston::Adapters::VersionControl::GitAdapter.credentials
        project.repo.origin.push deleted_refs, credentials: credentials
        Rails.logger.info "\e[34m[repo:prune] Completed in %.2fs\e[0m" % (Time.now - started_at)
        Rails.logger.debug branches.map { |branch| " - #{branch}\n" }.join
      end
    end
  end

  # date = Date.today
  # User.with_email_address(FULL_TIME_DEVELOPERS).each do |user|
  #   report = Houston::Reports::WeeklyUserReport.new(user, date)
  #   Houston::Reports::Mailer.weekly_user_report(report, to: "bob.lail@cph.org").deliver!
  # end

  every "1h", "measure:star" do
    measure_star_time!
  end

  every "2m", "remind:alerts" do
    require "yaml/store"
    store = YAML::Store.new("reminders.yml")

    threshold = 4.hours.from_now
    end_of_day = 16 # 4:00pm

    threshold += 16.hours if threshold.hour > end_of_day # is it afternoon? see what alerts are due in the morning.
    threshold += 1.day if threshold.wday == 6 # advance Saturday to Sunday
    threshold += 1.day if threshold.wday == 0 # advance Sunday to Monday
    alerts_coming_due = Houston::Alerts::Alert.open.checked_out.due_before(threshold)

    reminders = alerts_coming_due.pluck(:id, :checked_out_by_id).map { |ids| ids.join("-") }
    reminders_sent = store.transaction { store[:reminders_sent] } || []
    reminders_sent &= reminders # prune reminders for closed or late Alerts
    reminders_needed = reminders - reminders_sent

    # reminders_needed will be an array of strings like /:alert_id-:user_id/
    # we can treat these like an array of IDs because when calling `:to_i`
    # on a string like that, Ruby will return everyting up to the hyphen:
    # that is, the Alert ID.
    Houston::Alerts::Alert.open.checked_out.where(id: reminders_needed).each do |alert|
      assignee = alert.checked_out_by
      seconds = alert.seconds_remaining
      next if seconds < 180 # Skip it if we're late or have less than 2 minutes
      
      Rails.logger.info "\e[34m[slack] reminding \e[1m#{assignee.first_name}\e[0;34m of alert due in \e[1m#{timeleft}\e[0m"
      
      message = "Hey #{assignee.first_name}, this *#{alert.type}*"
      message << " for #{alert.project.slug}" if alert.project
      
      due_date = alert.deadline.to_date
      if due_date == Date.today
        minutes = seconds / 60
        hours = minutes / 60
        minutes -= (hours * 60)
        
        # Round up to the next hour
        if minutes > 50
          minutes = 0
          hours += 1
        end
        
        if hours == 0
          timeleft = "#{minutes} minutes"
        elsif hours == 1
          timeleft = "1 hour"
          timeleft << " and #{minutes} minutes" if minutes >= 10
        else
          timeleft = "#{hours} hours"
          timeleft << " and #{minutes} minutes" if minutes >= 10
        end
        
        message << " is due in *#{timeleft}*"
      else
        date = due_date == Date.today + 1 ? "tomorrow" : due_date.strftime("%A")
        message << " is due *#{date} at #{alert.deadline.strftime("%-I:%M %P")}*"
      end
      
      slack_send_message_to message, assignee, attachments: [slack_alert_attachment(alert)]
      
      reminders_sent << "#{alert.id}-#{alert.checked_out_by_id}"
      store.transaction { store[:reminders_sent] = reminders_sent }
    end
  end



  # Other
  # ---------------------------------------------------------------------------

  # Should return an array of email addresses
  identify_committers do |commit|
    emails = [commit.committer_email]
    emails = ["#{$1}@cph.org", "#{$2}@cph.org"] if commit.committer_email =~ /^pair=([a-z\.]*)\+([a-z\.]*)@/
    emails
  end

  # When a ticket's description is updated, this block
  # allows you to parse the description and set additional
  # properties
  parse_ticket_description do |ticket|
    text = ticket.description.to_s
    antecedents = []
    antecedents.concat text.scan(/^[\s\-\*]*Goldmine:\s*([\d ,]+)/).flatten.map { |s| s.split(/, */) }.flatten.map { |number| "Goldmine:#{number}" }
    antecedents.concat text.scan(/^[\s\-\*]*Errbit:\s*([\d ,]+)/).flatten.map { |s| s.split(/, */) }.flatten.map { |number| "Errbit:#{number}" }
    ticket.antecedents = antecedents
  end



end




ERRBIT_BANKRUPTCY = Time.new(2014, 9, 1).freeze
ERRBIT_NEW_KEY_DATE = Time.new(2014, 11, 23).freeze

LUKE = "luke.booth@cph.org".freeze
BOB = "robert.lail@cph.org".freeze
BEN = "ben.govero@cph.org".freeze
ORDIE = "ordie.page@cph.org".freeze
CHASE = "chase.clettenberg@cph.org".freeze
MATT = "matt.kobs@cph.org".freeze
FULL_TIME_DEVELOPERS = [LUKE, BOB, BEN, ORDIE, CHASE, MATT].freeze

JEREMY = "jeremy.roegner@cph.org".freeze
MEAGAN = "meagan.thole@cph.org".freeze
BRAD = "brad.egberts@cph.org".freeze

SLACK_USERNAME_FOR_USER = {
  BEN => "@bengovero",
  BOB => "@boblail",
  LUKE => "@luke",
  MEAGAN => "@meagan",
  BRAD => "@brad",
  ORDIE => "@ordiep",
  JEREMY => "@jeremy",
  CHASE => "@chase",
  MATT => "@kobsy"
}.freeze

STAR_USERNAME_FOR_USER = {
  BEN => "GOVEROBT",
  BOB => "LAILRC",
  LUKE => "BOOTHJL",
  ORDIE => "PAGEOE",
  CHASE => "CLETTECA",
  MATT => "KOBSMC"
}.freeze

TICKET_TAGS_FOR_UNFUDDLE = {
  nil                             => nil,
  "0 Suggestion"                  => "[Suggestion](0088CC)",
  "D Development"                 => nil,
  "R Refactor"                    => "[Refactor](98C221)",
  "1 Lack of Polish"              => "[Lack of Polish](ACC042)",
  "1 Visual Bug"                  => nil,
  "P Performance"                 => "[Performance](ACC042)",
  "2 Confusing to Users"          => "[Confusing](E9A43F)",
  "3 Design Flaw"                 => "[Spec Flaw](E9A43F)",
  "4 Broken (with work-around)"   => nil,
  "S Security Hole"               => "[Security](D65B17)",
  "5 Broken (no work-around)"     => "[No Work-Around](C1311E)"
}



def slack_send_message_to(message, channel, options={})
  if channel.is_a?(User)
    channel = SLACK_USERNAME_FOR_USER[channel.email]
    
    unless channel
      Rails.logger.info "\e[34m[slack:say] I don't know the Slack username for #{channel.email}\e[0m"
      return
    end
  end
  
  if options.delete(:as) == :github
    options.merge!(
      as_user: false,
      username: "github",
      icon_url: "https://slack.global.ssl.fastly.net/5721/plugins/github/assets/service_128.png")
  end
  
  if !Rails.env.development?
    Houston::Slack.send message, options.merge(channel: channel)
  elsif options.delete(:test)
    message = "[#{channel}]\n#{message}" unless channel == "test"
    channel = "test"
    Houston::Slack.send message, options.merge(channel: channel)
  else
    Rails.logger.debug "\e[95m[slack:say] #{channel}: #{message}\e[0m"
  end
end

def slack_alert_attachment(alert, options={})
  title = slack_link_to(alert.summary, alert.url)
  title << " {{#{alert.type}:#{alert.number}}}" if alert.number
  attachment = {
    fallback: "#{slack_escape(alert.summary)} - #{alert.url} - #{alert.number}",
    title: title,
    color: slack_project_color(alert.project) }

  attachment.merge!(text: alert.text) unless alert.text.blank?
  attachment
end

def slack_project_color(project)
  "##{project.color_value}" if project
end

def slack_link_to_pull_request(pr)
  url = pr._links ? pr._links.html.href : pr.pull_request.html_url
  slack_link_to "##{pr.number} #{pr.title}", url
end

def slack_link_to(message, url)
  return message unless url
  "<#{url}|#{slack_escape(message)}>"
end

def slack_escape(message)
  message.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "gt;").gsub(/[\r\n]/, " ")
end



class TemporaryCredentials
  def with_credentials
    yield "Houston", ENV["HOUSTON_CPH_PASSWORD"]
  end
end



def to_end_of_thursday(time)
  days_until_thursday = 4 - time.wday
  days_until_thursday += 7 if days_until_thursday < 0
  days_until_thursday.days.from(time).end_of_day
end

def measure_star_time!(time=Time.now)
  # Find entries for the last 3 weeks
  taken_at = to_end_of_thursday(time)
  date = taken_at.to_date
  weeks = (-14..0).step(7).map { |ago| (date + (ago - 6))..(date + ago) }
  weeks.each do |week|
    measure_star_time_for_week!(week)
  end
end

def measure_star_time_for_year!
  now = Time.now
  measure_alerts_for_range!(Time.new(now.year, 1, 1)..now)
end

def measure_star_time_for_range!(range)
  taken_at = to_end_of_thursday(range.begin).to_date
  while taken_at < range.end
    week = (taken_at - 6)..taken_at
    measure_star_time_for_week!(week)
    taken_at = 7.days.after(taken_at)
  end
end

def measure_star_time_for_week!(week)
  star = Star.new(TemporaryCredentials.new)
  taken_at = week.end.to_time.end_of_day
  
  all_star_entries = STAR_USERNAME_FOR_USER.flat_map do |email, username|
    user = User.find_by_email(email)
    star_entries_for_week = []
    unitime_entries_for_week = []
    
    week.each do |date|
      star_entries = star.get_time!(date, username)
      unitime_entries = star.get_unitime!(date, username)
      record_star_measurements!(
        taken_at: date.to_time.end_of_day,
        user: user,
        prefix: "daily",
        star_entries: star_entries,
        unitime_entries: unitime_entries)
      star_entries_for_week.concat star_entries
      unitime_entries_for_week.concat unitime_entries
    end
    
    record_star_measurements!(
      taken_at: taken_at,
      user: user,
      prefix: "weekly",
      star_entries: star_entries_for_week,
      unitime_entries: unitime_entries_for_week)
    
    star_entries_for_week
  end
  
  all_star_entries.group_by { |attrs| attrs[:project] }.each do |project_slug, star_entries|
    project = Project.find_by_slug project_slug
    next unless project
    
    Measurement.take!(subject: project, taken_at: taken_at, name: "weekly.hours.charged",
      value: star_entries.sum { |attrs| attrs[:hours] })
    
    star_entries.group_by { |attrs| attrs[:component] }.each do |component, star_entries|
      Measurement.take!(subject: project, taken_at: taken_at, name: "weekly.hours.charged.#{component}",
        value: star_entries.sum { |attrs| attrs[:hours] })
    end
  end
end

def record_star_measurements!(taken_at: nil, user: nil, prefix: nil, star_entries: nil, unitime_entries: nil)
  hours_worked = unitime_entries.select { |attrs| attrs[:pay_code] == :regular }.sum { |attrs| attrs[:hours] }
  hours_off = unitime_entries.select { |attrs| [:timeoff, :holiday].member?(attrs[:pay_code]) }.sum { |attrs| attrs[:hours] }
  hours_charged = star_entries.sum { |attrs| attrs[:hours] }
  
  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.worked", value: hours_worked)
  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.off", value: hours_off)
  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.charged", value: hours_charged)
  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.charged.percent",
    value: (hours_charged.to_f / hours_worked).round(4)) if hours_worked > 0
  
  star_entries.group_by { |attrs| attrs[:component] }.each do |component, star_entries|
    Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.charged.#{component}",
      value: star_entries.sum { |attrs| attrs[:hours] })
  end
end





def measure_sprint_effort_for_week!(time=Time.now)
  taken_at = to_end_of_thursday(time)
  
  sprint = Sprint.find_by_date(taken_at)
  return unless sprint
  
  sprint.sprint_tasks.joins(:task)
    .group("sprints_tasks.checked_out_by_id")
    .pluck("sprints_tasks.checked_out_by_id", "SUM(tasks.effort)")
    .each do |(user_id, effort)|
      Measurement.take!(name: "weekly.sprint.effort.intended", taken_at: taken_at,
        subject_type: "User", subject_id: user_id, value: effort) if user_id
  end
  
  sprint.sprint_tasks.joins(:task)
    .completed_during(sprint)
    .group("sprints_tasks.checked_out_by_id")
    .pluck("sprints_tasks.checked_out_by_id", "SUM(tasks.effort)")
    .each do |(user_id, effort)|
      Measurement.take!(name: "weekly.sprint.effort.completed", taken_at: taken_at,
        subject_type: "User", subject_id: user_id, value: effort) if user_id
  end
  
  intended = sprint.sprint_tasks.joins(:task).sum("tasks.effort")
  completed = sprint.sprint_tasks.joins(:task).completed_during(sprint).sum("tasks.effort")
  Measurement.take!(name: "weekly.sprint.completed", taken_at: taken_at,
    value: intended == completed ? "1" : "0")
end



def measure_alerts_for_year!
  now = Time.now
  measure_alerts_for_range!(Time.new(now.year, 1, 1)..now)
end

def measure_alerts_for_range!(range)
  taken_at = to_end_of_thursday(range.begin)
  while taken_at < range.end
    measure_alerts_for_week!(taken_at)
    taken_at = 7.days.after(taken_at)
  end
end

def measure_alerts_for_week!(time=Time.now)
  taken_at = to_end_of_thursday(time)
  
  week = 6.days.before(taken_at).beginning_of_day..taken_at.end_of_day
  
  # Alerts Completed this Week
  alerts = Houston::Alerts::Alert.where(closed_at: week).includes(:checked_out_by)
  alerts.group_by(&:checked_out_by).each do |user, alerts|
    Measurement.take!(name: "weekly.alerts.completed", taken_at: taken_at, subject: user, value: alerts.count)
    alerts.group_by(&:type).each do |type, alerts|
      Measurement.take!(name: "weekly.alerts.completed.#{type}", taken_at: taken_at, subject: user, value: alerts.length)
    end
  end
  Measurement.take!(name: "weekly.alerts.completed", taken_at: taken_at, value: alerts.count)
  alerts.group_by(&:type).each do |type, alerts|
    Measurement.take!(name: "weekly.alerts.completed.#{type}", taken_at: taken_at, value: alerts.length)
  end
  
  # Alerts Opened this Week
  alerts = Houston::Alerts::Alert.where(opened_at: week).includes(:project)
  Measurement.take!(name: "weekly.alerts.opened", taken_at: taken_at, value: alerts.count)
  alerts.group_by(&:type).each do |type, alerts|
    Measurement.take!(name: "weekly.alerts.opened.#{type}", taken_at: taken_at, value: alerts.length)
  end
  alerts.group_by(&:project).each do |project, alerts|
    Measurement.take!(name: "weekly.alerts.opened", taken_at: taken_at, subject: project, value: alerts.count)
    alerts.group_by(&:type).each do |type, alerts|
      Measurement.take!(name: "weekly.alerts.opened.#{type}", taken_at: taken_at, subject: project, value: alerts.length)
    end
  end
  
  # Alerts Due this Week
  alerts = Houston::Alerts::Alert.where(deadline: week).includes(:checked_out_by) \
    .select { |alert| alert.deadline < week.end }
  
  alerts.group_by(&:checked_out_by).each do |user, alerts|
    if alerts.count > 0
      alerts_completed_on_time = alerts.select { |alert| alert.on_time?(week.end) != false }.count
      Measurement.take!(name: "weekly.alerts.due", taken_at: taken_at, subject: user,
        value: alerts.count)
      Measurement.take!(name: "weekly.alerts.due.completed-on-time", taken_at: taken_at, subject: user,
        value: alerts_completed_on_time)
      Measurement.take!(name: "weekly.alerts.due.completed-on-time.percent", taken_at: taken_at, subject: user,
        value: (alerts_completed_on_time.to_f / alerts.count).round(4))
    end
  end
  if alerts.count > 0
    alerts_completed_on_time = alerts.select { |alert| alert.on_time?(week.end) != false }.count.to_f
    Measurement.take!(name: "weekly.alerts.due", taken_at: taken_at,
      value: alerts.count)
    Measurement.take!(name: "weekly.alerts.due.completed-on-time", taken_at: taken_at,
      value: alerts_completed_on_time)
    Measurement.take!(name: "weekly.alerts.due.completed-on-time.percent", taken_at: taken_at,
      value: (alerts_completed_on_time.to_f / alerts.count).round(4))
  end
end




# star = Star.new(TemporaryCredentials.new)
# star.get! "/WebService.asmx/GetTimeForDay?date=2014/12/18"
# entries2 = ((Date.today-200)...Date.today).flat_map { |date| star.get_time!(date, "PARKKF") }; entries2.length
#
# times = [Time.new(2014, 12, 25),
# Time.new(2014, 12, 18),
# Time.new(2014, 12, 11),
# Time.new(2014, 12,  4)]
# 
# times.each { |time| measure_alerts_for_week!(time) }; nil
#
# times.each { |time| measure_star_time_for_week!(time) }; nil
#
# times = [
#   Time.new(2014,  8,  1),
#   Time.new(2014,  8,  8),
#   Time.new(2014,  8, 15),
#   Time.new(2014,  8, 22),
#   Time.new(2014,  8, 29),
#   Time.new(2014,  9,  5),
#   Time.new(2014,  9, 12),
#   Time.new(2014,  9, 19),
#   Time.new(2014,  9, 26),
#   Time.new(2014, 10,  3),
#   Time.new(2014, 10, 10),
#   Time.new(2014, 10, 17)
# ]
# 
# times.each { |time| measure_sprint_effort_for_week!(time) }; nil
#
# puts Measurement.debug
# 
# puts Measurement.order("taken_at ASC, subject_id ASC, name ASC").map { |m| "#{m.taken_on.strftime("%-m/%-d").rjust(5)} #{m.subject.try(:first_name).to_s.ljust(9)} #{m.name.ljust(32)} #{m.value.rjust(8)}" }
#
# puts Measurement.order("taken_at ASC, subject_id ASC, name ASC").map { |m| "#{m.taken_on.strftime("%-m/%-d").rjust(5)} #{m.name.ljust(32)} #{m.value.rjust(8)}" }


# Useful stuff
#
# List products whose Gemfiles we can't read:
# Project.where(category: "Products").reject(&:locked_gems).map(&:name)
#
# List dependencies with a column for related projects:
# puts "Name,License,Type,Language,Used in\n" + Project.where(category: "Products").each_with_object(Hash.new { |h, k| h[k] = [] }) { |p, map| p.locked_gems.specs.each { |s| map[s.name].push(p.name) } if p.locked_gems }.map { |gem, products| CSV.generate_line([gem, "", "Library", "Ruby", products.join(", ")]) }.join

# Test Reports
# Houston::Reports::Mailer.weekly_user_report(Houston::Reports::WeeklyUserReport.new(User.find(11), Date.new(2014, 9, 25)), to: "bob.lail@cph.org").deliver!
# Houston::Reports::Mailer.weekly_user_report(Houston::Reports::WeeklyUserReport.new(User.find(1), Date.new(2014, 10, 25)), to: "bob.lail@cph.org").deliver!

def get_time_records_for(user, during: nil)
  measurements = Measurement.for(user)
    .named("daily.hours.{charged,worked,off}")
    .taken_on(during)
  
  during.map do |date|
    charged = measurements.find { |m| m.taken_on?(date) && m.name == "daily.hours.charged" }.try(:value).to_s.to_d
    worked = measurements.find { |m| m.taken_on?(date) && m.name == "daily.hours.worked" }.try(:value).to_s.to_d
    off = measurements.find { |m| m.taken_on?(date) && m.name == "daily.hours.off" }.try(:value).to_s.to_d
    recorded = worked + off
    star_goal = (user.id == 1 ? 0.25 : 0.5) * worked
    empower_goal = 6.0

    { date: date,
      charged: charged,
      worked: worked,
      off: off,
      recorded: worked + off }
  end
end

ORDINALS = %w{
  zero
  first
  second
  third
  fourth
  fifth
  sixth
  seventh
  eighth
  ninth
  tenth
  eleventh
  twelfth
  thirteenth
  fourteenth
  fifteenth
  sixteenth
  seventeenth
  eighteenth
  nineteenth
  twentieth
  twenty-first
  twenty-second
  twenty-third
  twenty-fourth
  twenty-fifth
  twenty-sixth
  twenty-seventh
  twenty-eighth
  twenty-ninth
  thirtieth
  thirty-first
}.freeze

NUMERALS = {
  2015 => "Two Thousand and Fifteen",
  2016 => "Two Thousand and Sixteen",
  2017 => "Two Thousand and Seventee",
  2018 => "Two Thousand and Eighteen"
}.freeze



Houston.observer.fire "boot"
