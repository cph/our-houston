require_relative "../../../lib/side_project/base"
require "ostruct"

Houston::Conversations.config do
  listen_for "deploy {{number:core.number.integer.positive}}",
             # A complete regex looks like this: http://stackoverflow.com/a/12093994/731300
             %q{deploy (?<branch>[\w\d\+\-\._\/]+)} do |e|

    e.responding

    unless e.user
      e.reply "I'm sorry. I don't know who you are."
      next
    end

    unless e.user.developer?
      e.reply "I'm sorry. You have to be a developer to deploy a pull request"
      next
    end

    target = "number" if e.matched? "number"
    target = "branch" if e.matched? "branch"
    value = e.match[target]

    Rails.logger.info "[houston:deploy] starting deploy of #{target} #{value}"
    Houston::SideProject::Deploy.start!(e, target, value)
  end
end

Houston::Slack.config do
  slash("deploy") do |e|
    unless e.user
      e.respond! "I'm sorry. I don't know who you are."
      next
    end

    unless e.user.developer?
      e.respond! "I'm sorry. You have to be a developer to deploy a pull request"
      next
    end

    # A complete regex looks like this: http://stackoverflow.com/a/12093994/731300
    match = e.message.match /(?:\#?(?<number>\d+)\b|(?<branch>[\w\d\+\-\._\/]+))/i
    target = "number" if match && match[:number].present?
    target = "branch" if match && match[:branch].present?
    unless target
      e.respond! "I'm sorry. I didn't get that. What?"
      next
    end

    value = match[target]
    e.respond! ":+1:"

    Houston::SideProject::Deploy.start!(e, target, value)
  end
end



module Houston
  module SideProject
    class Deploy < Base
      attr_reader :target, :pr, :project, :environment, :maintenance_page
      YESORNO = ["(?<affirmative>yes|ok|sure|yeah|ya)", "(?<negative>no)"].freeze
      ACKNOWLEDGEMENT = ["Alright, thanks.", "OK", "got it", "ok", "ok"].freeze
      DEPLOYABLE_REPOS = %w{
        cph/members
        cph/unite
        cph/ledger
        cph/lsb
      }.freeze



      def initialize(attributes)
        @target = attributes.fetch :target
        @executing = false
        super attributes.merge(description: "I am deploying #{target.value}")
      end

      def self.start!(e, target, value)
        super(
          user: e.user,
          conversation: e.start_conversation!,
          target: OpenStruct.new(type: target, value: value))
      end

      def start!
        find_pull_request
      end



      def find_pull_request
        Rails.logger.info "[houston:deploy] looking for pull requests"
        pulls = find_pull_requests_for_branch(target.value) if target.type == "branch"
        pulls = find_pull_requests_with_number(target.value.to_i) if target.type == "number"

        case pulls.length
        when 0
          if target.type == "branch"
            find_branch
          else
            end! "I couldn't find an open pull request with the #{target.type} #{target.value}."
          end

        when 1
          @pr = pulls[0]
          @project = Project.find_by_slug!(pr.base.repo.name)
          determine_deploy_strategy

        else
          repos = pulls.map { |pr| pr.base.repo.name }

          advise "I'm waiting to hear which pull request I should deploy"
          conversation.ask "#{repos.map { |name| "*#{name}*" }.to_sentence} #{repos.length == 2 ? "both" : "all"} have pull requests with the #{target.type} *#{target.value}*. Which one should I deploy?", expect: match_repo(repos) do |e|
            @pr = pulls.detect { |pr| pr.base.repo.name == e.match["repo"] }
            @project = Project.find_by_slug!(pr.base.repo.name)
            determine_deploy_strategy
          end
        end

      rescue ActiveRecord::RecordNotFound
        end! "Sorry, I'm not sure what project you want to deploy :sweat:"
      rescue Exception
        Houston.report_exception $!
        end! ":rotating_light: Uh-oh. I just got this error: #{$!.message}"
      end

      def find_pull_requests_for_branch(branch)
        advise "I am looking for a pull request for *#{branch}*"
        list_all_pull_requests.select { |pr| pr.head.ref == branch }
      end

      def find_pull_requests_with_number(number)
        advise "I am looking for a pull request numbered *#{number}*"
        list_all_pull_requests.select { |pr| pr.number == number }
      end



      def find_branch
        Rails.logger.info "[houston:deploy] looking for a branch"
        branch = target.value
        advise "I am looking for a branch named *#{branch}*"
        repos = find_repos_with_a_branch_named(branch)

        case repos.length
        when 0
          end! "I couldn't find a branch named *#{branch}*. Is that spelling right?"

        when 1
          @project = Project.find_by_slug!(repos[0])
          create_pull_request_for_branch

        else
          advise "I'm waiting to hear which branch I should deploy"
          conversation.ask "#{repos.map { |name| "*#{name}*" }.to_sentence} #{repos.length == 2 ? "both" : "all"} have branches named *#{branch}*. Which one should I deploy?", expect: match_repo(repos) do |e|
            @project = Project.find_by_slug!(e.match["repo"])
            create_pull_request_for_branch
          end
        end

      rescue ActiveRecord::RecordNotFound
        end! "Sorry, I'm not sure what project you want to deploy :sweat:"
      rescue Exception
        Houston.report_exception $!
        end! ":rotating_light: Uh-oh. I just got this error: #{$!.message}"
      end



      def create_pull_request_for_branch
        Rails.logger.info "[houston:deploy] creating a pull request"
        branch = target.value
        repo = project.repo

        # !todo: the pull request could've been created in the meantime...
        @pr = repo.create_pull_request(base: "master", head: branch, title: branch.titleize)
        repo.add_labels_to %w{review-needed test-needed}, pr.number

        conversation.reply "I created a pull request for that branch, #{slack_link_to_pull_request(pr)}. Would you add testing instructions?"
        determine_deploy_strategy

      rescue Octokit::UnprocessableEntity
        end! "Sorry, I couldn't find a pull request for the branch *#{branch}* and I got an error when trying to create one. :disappointed:"
      rescue Exception
        Houston.report_exception $!
        end! ":rotating_light: Uh-oh. I just got this error: #{$!.message}"
      end



      # !todo: strictly, all of the following should be atomic
      def determine_deploy_strategy
        Rails.logger.info "[houston:deploy] determining deploy strategy"
        other_deploys = Houston.side_projects
          .select { |other| other.is_a? Houston::SideProject::Deploy }
          .reject { |other| other == self }
          .select { |other| other.project && other.project.id == project.id }

        if deploy_by_other_user = other_deploys.find { |deploy| deploy.user != user }
          end! "I'm sorry. #{deploy_by_other_user.user.first_name} is deploying #{slack_link_to_pull_request deploy_by_other_user.pr} right now."
          return
        end

        if deploy_executing = other_deploys.find(&:executing?)
          end! "I'm sorry. #{slack_link_to_pull_request deploy_executing.pr} is being deployed right now."
          return
        end

        other_deploys.each(&:cancel!)

        # !todo: support other strategies
        # we're just deploying members, unite, and ledger to Staging for now,
        # so we can assume that the strategy is Engineyard
        environment_name = project == "lsb" ? "staging2" : "staging"
        @environment = Houston::Adapters::Deployment::Engineyard.new(project, environment_name)
        check_if_another_pull_request_is_on_staging
      rescue Exception
        Houston.report_exception $!
        end! ":rotating_light: Uh-oh. I just got this error: #{$!.message}"
      end



      def check_if_another_pull_request_is_on_staging
        Rails.logger.info "[houston:deploy] checking if another pull request is on staging"
        advise nil
        other_pr = list_pull_requests_on_staging_for_project(project)
          .reject { |pr| pr.number == self.pr.number }
          .reject { |pr| pr.labels.any? { |label| label.name == "test-complete" } }
          .first

        if other_pr
          # !todo: this could be cached
          user = User.find_by_email_address Houston.github.user(other_pr.user.login).email
          advise "I'm waiting to hear if I can have staging"
          question = "#{user == self.user ? "You have" : "#{user ? user.first_name : other_pr.user.login} has"} #{slack_link_to_pull_request(other_pr)} on staging. Is it OK for me to deploy #{target.value}?"
          question = "#{self.user.slack_username}, #{question}" unless self.user.slack_username.blank?
          conversation.ask question, expect: YESORNO do |e|
            if e.matched?("affirmative")
              execute_deploy
            else
              end! "ok. I won't deploy it."
            end
          end
        else
          execute_deploy
        end
      rescue Exception
        Houston.report_exception $!
        end! ":rotating_light: Uh-oh. I just got this error: #{$!.message}"
      end



      def executing?
        @executing
      end

      def execute_deploy
        Rails.logger.info "[houston:deploy] deploying"
        advise nil
        @executing = true
        return pretend_to_deploy if Rails.env.development?

        deploy = ::Deploy.create!(
          project: project,
          environment_name: "staging",
          sha: pr.head.sha,
          branch: pr.head.ref,
          deployer: user.email)

        advise "It started at #{deploy.created_at.strftime("%b %e, %l:%M %p")}."
        conversation.say "I am deploying #{slack_link_to_pull_request(pr)}"
        conversation.say "You can follow my progress #{slack_link_to "here", deploy.url}"

        if environment.deploy(deploy, maintenance_page: maintenance_page)
          end! "I have finished deploying #{target.value} (#{slack_link_to "output", deploy.url})"
        else
          end! ":rotating_light: #{user.first_name}, the deploy of #{target.value} just failed. (#{slack_link_to "output", deploy.url})"
        end

      rescue EY::CloudClient::RequestFailed
        Houston.report_exception $!
        end! ":rotating_light: I'm sorry. An error occurred: #{$!.message}"
      rescue EY::CloudClient::BadBridgeStatusError
        Houston.report_exception $!
        end! ":rotating_light: Uh-oh. I just got this error: #{$!.message}"
      rescue Exception
        Houston.report_exception $!
        end! ":rotating_light: Uh-oh. I just got this error: #{$!.message}"
      end

      def pretend_to_deploy
        conversation.say "I am deploying #{slack_link_to_pull_request(pr)}"
        sleep 6
        end! "I am done"
      end



    private

      def list_all_pull_requests
        DEPLOYABLE_REPOS.flat_map { |repo| Houston.github.pulls(repo) }
      end

      def list_pull_requests_on_staging_for_project(project)
        Houston.github.list_issues(
          "cph/#{project.slug}",
          labels: "on-staging",
          filter: "all")
            .select(&:pull_request)
      end

      def match_repo(repos)
        "(?<repo>#{Regexp.union(repos)})"
      end

      def find_repos_with_a_branch_named(branch)
        DEPLOYABLE_REPOS.select do |repo|
          begin
            Array.wrap(Houston.github.refs(repo, "heads/#{branch}"))
              .select { |ref| ref.ref == "refs/heads/#{branch}" }
              .any?
          rescue Octokit::NotFound
            false
          end
        end.map { |full_name| full_name.split("/").last }
      end

    end
  end
end
