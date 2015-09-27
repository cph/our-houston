Houston.config.at "6:30pm", "repo:prune", every: :sunday do
  credentials = Houston::Adapters::VersionControl::GitAdapter.credentials

  %w{members unite ledger}.each do |project_slug|
    project = Project.find_by_slug(project_slug)

    # Don't delete certain required branches
    # or any branch which is the head or target
    # of an open pull request.
    protected_branches = %w{master beta dev}.to_set
    project.repo.pull_requests.each do |pr|
      protected_branches.add(pr.head.ref).add(pr.base.ref)
    end

    # List remote branches, not local branches
    remote_branches = project.repo.origin.ls(credentials: credentials)
      .map { |attrs| attrs[:name] }
      .grep(/^refs\/heads\//)
      .map { |name| name[11..-1] }

    branches = remote_branches - protected_branches.to_a
    if branches.any?
      Rails.logger.info "\e[34m[repo:prune] Deleting \e[1m#{branches.length}\e[0;34m branches from \e[1m#{project_slug}\e[0m"

      started_at = Time.now
      deleted_refs = branches.map { |branch| ":refs/heads/#{branch}" }
      project.repo.origin.push deleted_refs, credentials: credentials
      Rails.logger.info "\e[34m[repo:prune] Completed in %.2fs\e[0m" % (Time.now - started_at)

      message = "I pruned #{branches.length} branches from *#{project_slug}*:\n```#{branches.join("\n")}\n```"
      slack_send_message_to message, "developers"
    end
  end
end
