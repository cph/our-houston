Houston.config.on "release:create" do |release|
  release_url = "http://#{Houston.config.host}/releases/#{release.id}"
  message = "New release for #{release.project.name}: #{release_url}"

  slack_send_message_to message, "#releases"
end
