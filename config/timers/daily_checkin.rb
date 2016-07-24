Houston.config.at [:weekday, "7:45am"], "prompt:checkin" do
  slack_send_message_to "Hey @channel, what's everyone working on today?", "ep-checkin"
end
