Houston.config.at "6:30pm", "repo:prune", every: :sunday do
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
