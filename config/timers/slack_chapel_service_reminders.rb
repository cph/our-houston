Houston.config.every "friday at 8am", "reminders:upcoming-chapel-service" do
  next_service = Presentation::ChapelService.next_within_a_week
  next unless next_service
  next unless next_service.presenter.slack_username
  message = "Friendly reminder: you're leading chapel next week! :slightly_smiling_face:"
  message << " (please make sure you've added a hymn and liturgy so they can be sent to the right people)" unless next_service.summary_complete?
  slack_send_message_to message, next_service.presenter.slack_username,
    attachments: slack_chapel_service_attachment(next_service)
end
