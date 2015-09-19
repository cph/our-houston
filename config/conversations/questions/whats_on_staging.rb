Houston::Slack.config do
  listen_for(/what.* on staging\?/i) do |e|
    pulls = Houston.github.org_issues(Houston.config.github[:organization], labels: "on-staging", filter: "all")
    e.reply "There are no pull requests on Staging" if pulls.none?
    e.reply pulls.map { |pr| "For *#{pr.repository.name}*, #{slack_link_to_pull_request(pr)} is on Staging" }
  end
end
