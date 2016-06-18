Houston.observer.on "slack:reaction:added" do |e|
  next unless value = e.emoji[/signal_strength_(\d)/, 1]

  id = e.message.text[/<https?:\/\/[^\/>]+\/feedback\/(\d+)>/, 1]
  comment = id && Houston::Feedback::Comment.find_by_id(id)
  next unless comment && e.user

  Rails.logger.info "\e[35m#{e.user.name} set signal_strength of comment ##{comment.id} to #{value}\e[0m"
  comment.set_signal_strength_by! e.user, value
end

Houston.observer.on "slack:reaction:removed" do |e|
  next unless value = e.emoji[/signal_strength_(\d)/, 1]

  id = e.message.text[/<https?:\/\/[^\/>]+\/feedback\/(\d+)>/, 1]
  comment = id && Houston::Feedback::Comment.find_by_id(id)
  next unless comment && e.user

  next unless comment.get_signal_strength_by(e.user) == value.to_i

  Rails.logger.info "\e[35m#{e.user.name} cleared signal_strength of comment ##{comment.id}\e[0m"
  comment.set_signal_strength_by! e.user, nil
end
