Houston.config.on "alert:err:deployed" do |alert, deploy, commit|
  project = deploy.project
  error_tracker = project.error_tracker
  repo = project.repo

  # TODO: link to deploy
  message = "Resolved by Houston when #{commit.sha[0...7]} was deployed to #{deploy.environment_name}"
  message << "\n#{repo.commit_url(commit.sha)}" if repo.respond_to?(:commit_url)

  Houston.try({max_tries: 3, ignore: true}, Faraday::Error::TimeoutError) do
    error_tracker.resolve! alert.number, message: message
  end
end
