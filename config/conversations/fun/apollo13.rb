Houston::Slack.config do
  listen_for(/(i|we) have a problem/i) do |e|
    e.random_reply(
      "I'd like you to attempt to reconnect fuel cell 1 to MAIN A and fuel cell 3 to MAIN B. Verify that quad Delta is open." => 0.1,
      "This is Houston. Say again, please." => 0.3,
      "Okay, stand by, #{e.sender}. I'm looking at it." => 0.3,
      "Roger." => 0.3)
  end
end
