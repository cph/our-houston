Houston::Slack.config do
  listen_for(/what are you (?:doing|working on)\?/) do |e|
    e.reply "Nothing" if Houston.tdl.empty?
    e.reply Houston.tdl.map(&:describe)
  end
end
