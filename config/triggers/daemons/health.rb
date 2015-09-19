Houston.config do
  on "daemon:scheduler:restart" do
    slack_send_message_to "The thread running Rufus::Scheduler errored out and is attempting to recover", "@boblail"
  end

  on "daemon:scheduler:stop" do
    slack_send_message_to ":rotating_light: The thread running Rufus::Scheduler has terminated", "@boblail"
  end

  on "daemon:slack:restart" do
    slack_send_message_to "The thread running Slack errored out and is attempting to recover", "@boblail"
  end

  on "daemon:slack:stop" do
    slack_send_message_to ":rotating_light: The thread running Slack has terminated", "@boblail"
  end

  on "slack:error" do |args|
    slack_send_message_to "An error occurred\n#{args.inspect}", "@boblail"
  end
end
