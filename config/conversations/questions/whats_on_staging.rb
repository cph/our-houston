Houston::Conversations.config do
  listen_for "what is on staging" do |e|
    e.responding

    pulls = Houston.github.org_issues(Houston::Commits.config.github[:organization], labels: "on-staging", filter: "all")
    if pulls.none?
      e.reply "There are no pull requests on Staging"
      next
    end

    message = ""
    pulls.each do |pull|
      message << "*#{pull.repository.name.capitalize}* has #{slack_link_to_pull_request(pull)} on Staging\n"
      pull.labels.each { |lb| message << "`#{lb.name}` " }
      message << "\n"
    end

    e.reply message
  end
end
