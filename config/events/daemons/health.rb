Houston.config do
  on "daemon:scheduler:restart" => "daemon:slack-bob-that-scheduler-restarted" do
    slack_send_message_to "The thread running Rufus::Scheduler errored out and is attempting to recover", "@boblail"
  end

  on "daemon:scheduler:stop" => "daemon:slack-bob-that-scheduler-stopped" do
    slack_send_message_to ":rotating_light: The thread running Rufus::Scheduler has terminated", "@boblail"
  end

  on "daemon:slack:restart" => "daemon:slack-bob-that-slack-restarted" do
    slack_send_message_to "The thread running Slack errored out and is attempting to recover", "@boblail"
  end

  on "daemon:slack:stop" => "daemon:slack-bob-that-slack-stopped" do
    slack_send_message_to ":rotating_light: The thread running Slack has terminated", "@boblail"
  end

  on "slack:error" => "slack:slack-bob-of-slack-error" do
    slack_send_message_to "An error occurred\n#{message}", "@boblail"
  end
end
