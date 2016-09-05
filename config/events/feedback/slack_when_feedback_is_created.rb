Houston.config do
  on "feedback:create" => "feedback:announce-in-slack" do
    project_channel = "##{conversation.project.slug}"
    next unless Houston::Slack.connection.channels.include? project_channel

    # GOTCHA: this was triggered from an after_save callback.
    # We don't want this thread to run until the transaction has
    # been committed on the main thread — or else this conversation
    # won't be visible to Slack.
    sleep 0.1

    message = feedback_unfurl_url(conversation)
    slack_send_message_to message, project_channel
  end
end
