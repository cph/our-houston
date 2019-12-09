Houston.config.every "friday at 8am", "reminders:upcoming-chapel-service" do
  next_service = Presentation::ChapelService.next_within_a_week
  next unless next_service
  next unless next_service.presenter.slack_username
  message = "Friendly reminder: you're leading chapel next week! :slightly_smiling_face:"
  message << " Please make sure you've added a hymn and liturgy so they can be sent to the right people." unless next_service.summary_complete?
  slack_send_message_to message, next_service.presenter.slack_username,
    attachments: [slack_chapel_service_attachment(next_service)]
end

Houston.config.every "monday at 8am", "reminders:incomplete-chapel-service" do
  next_service = Presentation::ChapelService.next_within_a_week
  next unless next_service
  next unless next_service.presenter.slack_username
  next if next_service.summary_complete? || next_service.summary_sent?
  message = "Sorry to bother you, but it looks like you haven't completed the information for your upcoming chapel service this week. "
  message << "Please make sure at least the hymn and liturgy fields are entered so I can send the summary to the right people at 10:00 this morning. Thanks!"
  slack_send_message_to message, next_service.presenter.slack_username,
    attachments: [slack_chapel_service_attachment(next_service)]
end
