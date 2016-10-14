Houston.config do
  on "feedback:add" => "feedback:announce-in-slack" do
    project = conversation.project.slug
    feedback_channels = %W{#{project}-feedback ##{project}-feedback #{project} ##{project}}
    channel = feedback_channels.find { |channel| Houston::Slack.connection.can_see?(channel) }
    next unless channel

    # GOTCHA: this was triggered from an after_save callback.
    # We don't want this thread to run until the transaction has
    # been committed on the main thread — or else this conversation
    # won't be visible to Slack.
    sleep 1.0

    message = feedback_unfurl_url(conversation)
    slack_send_message_to message, channel
  end
end
