Houston.config do
  on "github:pull:synchronize" => "github:add_missing_alert_links_to_pr" do
    alert_urls = Alert.joins(:commits).where(commits: { id: pull_request.commits.ids }).pluck(:url)
    return if alert_urls.none?

    existing_comments = Houston.github.issue_comments(pull_request.repo, pull_request.number)
    alert_urls.each do |alert_url|
      message = "cf. [#{alert_url}](#{alert_url})"
      next if existing_comments.any? { |comment| comment[:body] == message }

      Houston.github.add_comment(pull_request.repo, pull_request.number, message)
    end
  end

  on "github:pull:open" => "github:add_missing_alert_links_to_new_pr" do
    alert_urls = Alert.joins(:commits).where(commits: { id: pull_request.commits.ids }).pluck(:url)
    return if alert_urls.none?

    existing_comments = Houston.github.issue_comments(pull_request.repo, pull_request.number)
    alert_urls.each do |alert_url|
      message = "cf. [#{alert_url}](#{alert_url})"
      next if existing_comments.any? { |comment| comment[:body] == message }

      Houston.github.add_comment(pull_request.repo, pull_request.number, message)
    end
  end
end
