Houston.config.on "release:create" => "release:announce-in-slack" do
  release_url = "#{Houston.root_url}/releases/#{release.id}"
  message = "New release for #{release.project.name}: #{release_url}"

  slack_send_message_to message, "#releases"


  project = release.project.slug
  release_channels = %W{#{project}-releases ##{project}-releases #{project} ##{project}}
  release_channels = ["#houston-news"] if project == "our-houston"
  channel = release_channels.find { |channel| Houston::Slack.connection.can_see?(channel) }
  next unless channel

  slack_send_message_to ":rocket:   *New release!*   #{release_url}", channel
end
