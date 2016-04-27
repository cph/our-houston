Houston::Slack.config do
  listen_for "what are you doing?", "what are you working on?" do |e|
    e.reply "Nothing" if Houston.side_projects.empty?
    e.reply Houston.side_projects.map(&:describe)
  end
end
