Houston.config do
  on "slack:reaction:added" => "feedback:set-signal-strength-via-reaction" do
    next unless value = emoji[/signal_strength_(\d)/, 1]

    id = message.text[/<https?:\/\/[^\/>]+\/feedback\/(\d+)>/, 1]
    comment = id && Houston::Feedback::Conversation.find_by_id(id)
    next unless comment && sender.user

    Rails.logger.info "\e[35m#{sender.user.name} set signal_strength of comment ##{comment.id} to #{value}\e[0m"
    comment.set_signal_strength_by! sender.user, value
  end

  on "slack:reaction:removed" => "feedback:clear-signal-strength-via-reaction"  do
    next unless value = emoji[/signal_strength_(\d)/, 1]

    id = message.text[/<https?:\/\/[^\/>]+\/feedback\/(\d+)>/, 1]
    comment = id && Houston::Feedback::Conversation.find_by_id(id)
    next unless comment && sender.user

    next unless comment.get_signal_strength_by(sender.user) == value.to_i

    Rails.logger.info "\e[35m#{sender.user.name} cleared signal_strength of comment ##{comment.id}\e[0m"
    comment.set_signal_strength_by! sender.user, nil
  end
end
