Houston.config.every "10s", "slack:ping" do
  Houston::Slack.connection.connection.ping
end
