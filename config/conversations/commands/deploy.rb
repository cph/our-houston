require_relative "../../../lib/side_project/base"
require "ostruct"


Houston::Slack.config do
  # A complete regex looks like this: http://stackoverflow.com/a/12093994/731300
  listen_for(/deploy.*\s(?:\#?(?<number>\d+)\b|(?<branch>[\w\d\+\-\._\/]+))/i) do |e|
    target = "number" if e.matched? :number
    target = "branch" if e.matched? :branch

    if e.channel.name == "test" && Rails.env.production?
      # Ignore deploys initiated from the test channel in Production
      # Reserve this for testing deploys in Development
      next
    end

    unless e.user
      e.reply "I'm sorry. I don't know who you are."
      next
    end

    unless e.user.developer?
      e.reply "I'm sorry. You have to be a developer to deploy a pull request"
      next
    end

    Houston.side_projects.start! Houston::SideProject::Deploy.new(
      user: e.user,
      conversation: e.start_conversation!,
      target: OpenStruct.new(type: target, value: e.match[target]))
  end
end



module Houston
  module SideProject
    class Deploy < Base
      attr_reader :target, :pr, :project, :environment, :maintenance_page
      YESORNO = /(?<affirmative>yes|ok|sure|yeah|ya)|(?<negative>no)/i.freeze
      ACKNOWLEDGEMENT = ["Alright, thanks.", "OK", "got it", "ok", "ok"].freeze


      def initialize(attributes)
        @target = attributes.fetch :target
        @executing = false
        super attributes.merge(description: "I am deploying #{target.value}")
      end

      def start!
        find_pull_request
      end



      def find_pull_request
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
          @project = Project.find_by_slug(pr.base.repo.name)
          determine_deploy_strategy

        else
          repos = pulls.map { |pr| pr.base.repo.name }

          advise "I'm waiting to hear which pull request I should deploy"
          conversation.ask "#{repos.map { |name| "*#{name}*" }.to_sentence} #{repos.length == 2 ? "both" : "all"} have pull requests with the #{target.type} *#{target.value}*. Which one should I deploy?", expect: match_repo(repos) do |e|
            @pr = pulls.detect { |pr| pr.base.repo.name == e.match[:repo] }
            @project = Project.find_by_slug(pr.base.repo.name)
            determine_deploy_strategy
          end
        end
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
        branch = target.value
        advise "I am looking for a branch named *#{branch}*"
        repos = find_repos_with_a_branch_named(branch)

        case repos.length
        when 0
          end! "I couldn't find a branch named *#{branch}*. Is that spelling right?"

        when 1
          @project = Project.find_by_slug(repos[0])
          create_pull_request_for_branch

        else
          advise "I'm waiting to hear which branch I should deploy"
          conversation.ask "#{repos.map { |name| "*#{name}*" }.to_sentence} #{repos.length == 2 ? "both" : "all"} have branches named *#{branch}*. Which one should I deploy?", expect: match_repo(repos) do |e|
            @project = Project.find_by_slug(e.match[:repo])
            create_pull_request_for_branch
          end
        end
      end



      def create_pull_request_for_branch
        branch = target.value
        repo = project.repo

        # !todo: the pull request could've been created in the meantime...
        @pr = repo.create_pull_request(base: "master", head: branch, title: branch.titleize)
        repo.add_labels_to %w{review-needed test-needed}, pr.number

        conversation.reply "I created a pull request for that branch, #{slack_link_to_pull_request(pr)}. Would you add testing instructions?"
        determine_deploy_strategy

      rescue Octokit::UnprocessableEntity
        end! "Sorry, I couldn't find a pull request for the branch *#{branch}* and I got an error when trying to create one. :disappointed:"
      end



      # !todo: strictly, all of the following should be atomic
      def determine_deploy_strategy
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
        conversation.reply "ok"

        # !todo: support other strategies
        # we're just deploying members, unite, and ledger to Staging for now,
        # so we can assume that the strategy is Engineyard
        @environment = Houston::Adapters::Deployment::Engineyard.new(project, "staging")
        check_if_another_pull_request_is_on_staging
      end



      def check_if_another_pull_request_is_on_staging
        advise nil
        other_pr = list_pull_requests_on_staging_for_project(project)
          .reject { |pr| pr.number == self.pr.number }
          .reject { |pr| pr.labels.any? { |label| label.name == "test-complete" } }
          .first

        if other_pr
          # !todo: this could be cached
          user = User.find_by_email_address Houston.github.user(other_pr.user.login).email
          advise "I'm waiting to hear if I can have staging"
          conversation.ask "#{user == self.user ? "You have" : "#{user ? user.first_name : other_pr.user.login} has"} #{slack_link_to_pull_request(other_pr)} on staging. Is it OK for me to deploy #{target.value}?", expect: YESORNO do |e|
            if e.matched?(:affirmative)
              execute_deploy
            else
              end! "ok. I won't deploy it."
            end
          end
        else
          execute_deploy
        end
      end



      # !todo: connect to the database and figure out which migrations will actually run
      # def ensure_migrations_are_hot_compatible
      #   advise nil
      #   migrations = project.repo
      #     .changes(environment.last_deploy_commit, pr.head.sha)
      #     .grep(/^db\/migrate\//)
      #
      #   added = migrations.select(&:added?)
      #   modified = migrations.select(&:modified?)
      #   deleted = migrations.select(&:deleted?)
      #
      #   summary = []
      #   summary << "1 migration was added:" if added.length == 1
      #   summary << "#{added.length} migrations were added:" if added.length > 1
      #   summary << ("\n```\n" << added.map { |change| change.file[11..-1] }.join("\n") << "\n```\n") if added.length > 0
      #
      #   summary << "Also, " if added.length > 0 and (modified.length > 0 or deleted.length > 0)
      #   summary << "1#{" migration" if added.none?} was modified:" if modified.length == 1
      #   summary << "#{modified.length}#{" migrations" if added.none?} were modified:" if modified.length > 1
      #   summary << "\n```\n#{modified.map { |change| change.file[11..-1] }.join("\n")}```\n" if modified.length > 0
      #
      #   summary << "And " if modified.length > 0 and deleted.length > 0
      #   summary << "1#{" migration" if added.none? && modified.none?} was deleted:" if deleted.length == 1
      #   summary << "#{deleted.length}#{" migrations" if added.none? && modified.none?} were deleted:" if deleted.length > 1
      #   summary << "\n```\n#{deleted.map { |change| change.file[11..-1] }.join("\n")}```\n" if deleted.length > 0
      #
      #   summary = summary.join(" ")
      #   if added.any? || modified.any?
      #     advise "I'm waiting to hear if I should use the maintenance page"
      #     conversation.ask "It looks like #{summary}\nShould I put the maintenance page up?", expect: YESORNO do |e|
      #       @maintenance_page = e.matched?(:affirmative)
      #       e.reply ACKNOWLEDGEMENT.sample
      #       execute_deploy
      #     end
      #
      #     conversation.say "(I'd recommend putting the maintenance page up if the old version of #{project.slug} will break on the new schema.)"
      #   else
      #     @maintenance_page = false
      #     execute_deploy
      #   end
      # end



      def executing?
        @executing
      end

      def execute_deploy
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
      end

      def pretend_to_deploy
        conversation.say "I am deploying #{slack_link_to_pull_request(pr)}"
        sleep 6
        end! "I am done"
      end



    private

      def list_all_pull_requests
        %w{members unite ledger}.flat_map { |repo|
          Houston.github.pulls("#{github_org}/#{repo}") }
      end

      def list_pull_requests_on_staging_for_project(project)
        Houston.github.list_issues(
          "#{github_org}/#{project.slug}",
          labels: "on-staging",
          filter: "all")
            .select(&:pull_request)
      end

      def match_repo(repos)
        /(?<repo>#{Regexp.union(repos)})/i
      end

      def find_repos_with_a_branch_named(branch)
        %w{members unite ledger}.select do |repo|
          begin
            Houston.github
              .refs("#{github_org}/#{repo}", "heads/#{branch.chop}")
              .select { |ref| ref.ref == "refs/heads/#{branch}" }
              .any?
          rescue Octokit::NotFound
            false
          end
        end
      end

      def github_org
        Houston.config.github[:organization]
      end

    end
  end
end
