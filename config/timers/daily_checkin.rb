Houston.config.every "weekday at 7:45am", "prompt:checkin:ep" do
  slack_send_message_to "Hey @channel, what's everyone working on today?", "ep-checkin"
end

Houston.config.every "weekday at 1:45pm", "prompt:checkup:ep" do
  slack_send_message_to "Hey @channel, how's it going?", "ep-checkin"
end

