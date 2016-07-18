Houston.config do
  on "slack:reaction:added" => "feedback:set-signal-strength-via-reaction" do
    next unless value = emoji[/signal_strength_(\d)/, 1]

    id = message.text[/<https?:\/\/[^\/>]+\/feedback\/(\d+)>/, 1]
    comment = id && Houston::Feedback::Comment.find_by_id(id)
    next unless comment && user

    Rails.logger.info "\e[35m#{user.name} set signal_strength of comment ##{comment.id} to #{value}\e[0m"
    comment.set_signal_strength_by! user, value
  end

  on "slack:reaction:removed" => "feedback:clear-signal-strength-via-reaction"  do
    next unless value = emoji[/signal_strength_(\d)/, 1]

    id = message.text[/<https?:\/\/[^\/>]+\/feedback\/(\d+)>/, 1]
    comment = id && Houston::Feedback::Comment.find_by_id(id)
    next unless comment && user

    next unless comment.get_signal_strength_by(user) == value.to_i

    Rails.logger.info "\e[35m#{user.name} cleared signal_strength of comment ##{comment.id}\e[0m"
    comment.set_signal_strength_by! user, nil
  end
end
