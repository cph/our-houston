Houston.config.on "release:create" => "release:announce-in-slack" do
  release_url = "#{Houston.root_url}/releases/#{release.id}"

  project = release.project.slug
  release_channels = %W{#{project}-releases ##{project}-releases #{project} ##{project}}
  release_channels = ["#houston-news"] if project == "our-houston"
  channel = release_channels.find { |channel| Houston::Slack.connection.can_see?(channel) }
  message = channel.nil? ?
    "New release for #{release.project.name}: #{release_url}" :
    ":rocket:   *New release!*   #{release_url}"
  channel ||= "#releases"

  slack_send_message_to message, channel
end
