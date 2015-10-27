Houston::Slack.config do
  listen_for(/what.* on staging\?/i) do |e|
    pulls = Houston.github.org_issues(Houston.config.github[:organization], labels: "on-staging", filter: "all")
    e.reply "There are no pull requests on Staging" if pulls.none?
    message = ""
    pulls.each do |pull|
      message << "*#{pull.repository.name.capitalize}* has #{slack_link_to_pull_request(pull)} on Staging\n"
      pull.labels.each { |lb| message << "`#{lb.name}` " }
      message << "\n"
    end

    e.reply message
  end
end
