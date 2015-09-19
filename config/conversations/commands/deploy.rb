Houston::Slack.config do
  # A complete regex looks like this: http://stackoverflow.com/a/12093994/731300
  listen_for(/deploy.*\s(?:\#?(?<number>\d+)\b|(?<branch>[\w\d\+\-\._\/]+))/i) do |e|
    target = "number" if e.matched? :number
    target = "branch" if e.matched? :branch

    unless e.user
      e.reply "I'm sorry. I don't know who you are."
      next
    end

    unless e.user.developer?
      e.reply "I'm sorry. You have to be a developer to deploy a pull request"
      next
    end

    Houston.tdl.add(
      user: e.user,
      goal: "deploy",
      describe: "I am deploying #{e.match[target]}",
      step: "find-pr",
      conversation: e.start_conversation!,
      target: { type: target, value: e.match[target] })
  end
end

Houston.config do
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
end
