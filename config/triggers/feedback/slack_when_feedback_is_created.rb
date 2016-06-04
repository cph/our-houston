Houston.config do
  on "feedback:comment:create" do |comment|
    project_channel = "##{comment.project.slug}"
    next unless Houston::Slack.connection.channels.include? project_channel

    message = feedback_unfurl_url(comment)
    slack_send_message_to message, project_channel
  end
end
