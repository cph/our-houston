Houston::Conversations.config do
  listen_for("hello") do |e|
    e.reply "hello"
  end
end
