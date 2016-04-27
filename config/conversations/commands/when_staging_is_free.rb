Houston::Slack.config do
  listen_for "tell me when staging is free" do |e|
    project = Project.find_by_slug e.channel.name
    if project
      Houston.observer.once("staging:#{project.slug}:free") do
        e.reply "#{e.sender}, I think #{project.slug} staging might be free now"
      end
      e.reply "No problem"
    else
      e.reply "Sorry. I can only do that if you ask me in a project channel :confused:"
    end
  end
end
