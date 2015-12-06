Houston.config.on "release:create" do |release|
  release_url = "http://#{Houston.config.host}/releases/#{release.id}"
  message = "New release for #{release.project.name}: #{release_url}"

  channel = "##{release.project.slug}"
  channel = release.user.slack_channel if !Houston::Slack.connection.channels.include?(channel) && release.user

  slack_send_message_to message, channel if channel
end
