Houston.config do
  on "commit:create" => "github:add_alert_link_on_commit" do
    alerts = commit.identify_alerts
    next if alerts.none? || commit.pull_requests.none?

    commit.pull_requests.each do |pr|
      existing_comments = Houston.github.issue_comments(pr.repo, pr.number)

      alerts.each do |alert|
        message = "cf. [#{alert.url}](#{alert.url})"

        # Check for duplicates before posting. This could happen if a commit
        # is tagged with an alert, but then the PR is rebased, giving the
        # commit a different SHA.
        next if existing_comments.any? { |comment| comment[:body] == message }

        Houston.github.add_comment(pr.repo, pr.number, message)
      end
    end
  end
end
