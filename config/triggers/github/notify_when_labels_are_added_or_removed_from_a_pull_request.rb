Houston.config do
  on "github:pull:label-removed" do |pull_request, label|
    channel = "##{pull_request.project.slug}"
    channel = "developers-only" unless Houston::Slack.connection.channels.include? channel

    message = "#{pull_request.actor || "Someone"} removed `#{label}` from #{slack_link_to_pull_request(pull_request)}"

    slack_send_message_to message, channel, as: :github
  end

  on "github:pull:label-added" do |pull_request, label|
    channel = "##{pull_request.project.slug}"
    channel = "developers-only" unless Houston::Slack.connection.channels.include? channel

    message = "#{pull_request.actor || "Someone"} added `#{label}` to #{slack_link_to_pull_request(pull_request)}"

    slack_send_message_to message, channel, as: :github
  end



  on "github:pull:label-added" do |pull_request, label|
    next unless label == "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pull_request)} is ready for review"
    slack_send_message_to message, "#code-review"
  end

  on "github:pull:opened" do |pull_request|
    next unless pull_request.labeled? "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pull_request)} is ready for review"
    slack_send_message_to message, "#code-review"
  end
end
