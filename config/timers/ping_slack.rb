Houston.config.every "10s", "slack:ping" do
  next unless Houston::Slack.connection.listening?
  Houston::Slack.connection.ping
end
