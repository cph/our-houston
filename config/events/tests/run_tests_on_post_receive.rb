Houston.config do
  # Here's how this works:
  #
  #   1. GitHub receives a `git push` and triggers all Web Hooks:
  #      POST /projects/houston/hooks/post_receive.
  #   2. Houston receives this request and fires the
  #      'hooks:project:post_receive' event.
  #   3. Houston creates a TestRun and tells a CI server to build
  #      then corresponding job:
  #      POST /job/houston/buildWithParameters.
  on "hooks:project:post_receive" => "run-tests-on-post-receive" do
    next unless project.has_ci_server?
    next unless project.ci_server_name == "Jenkins"
    payload = PostReceivePayload.new(params).to_h
    commit = project.find_commit_by_sha(payload.fetch(:sha))

    # Since we're using GitHub's Branch Protection on the master
    # branch, skip running tests for merge commits to master.
    next if payload.fetch(:branch) == "master" && commit&.merge?

    project.create_a_test_run(payload)
  end

  #   4. Houston notifies GitHub that the test run has started:
  #      POST /repos/houston/houston/statuses/:sha
  action "test-run:publish-status-to-github", ["test_run"] do
    test_run.publish_status_to_github
  end

  on "test_run:start" => "test-run:publish-status-to-github"

  #   5. Jenkins checks out the project, runs the tests, and
  #      tells Houston that it is finished:
  #      POST /projects/houston/hooks/post_build.
  #   6. Houston receives the request and fires the
  #      'hooks:post_build' event.
  #   7. Houston updates the TestRun,
  #      fetching additional details from Jenkins:
  #      GET /job/houston/19/testReport/api/json
  on "hooks:post_build" => "fetch-results-on-post-build" do
    commit, results_url = params.values_at(:commit, :results_url)
    test_run = project.test_runs.find_or_create_by_sha(commit)
    test_run.notify_of_invalid_configuration do
      test_run.completed!(results_url)
    end
  end

  #   8. Houston publishes results to GitHub:
  #      POST /repos/houston/houston/statuses/:sha
  on "test_run:complete" => "test-run:publish-status-to-github"
end
