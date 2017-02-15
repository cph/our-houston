Houston::Conversations.config do
  listen_for("what channel is this?") { |e| e.reply e.channel.to_s }
end
