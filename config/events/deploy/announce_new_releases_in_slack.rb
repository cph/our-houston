Houston.config.on "release:create" => "release:announce-in-slack" do
  release_url = "#{Houston.root_url}/releases/#{release.id}"
  message = "New release for #{release.project.name}: #{release_url}"

  slack_send_message_to message, "#releases"
end
