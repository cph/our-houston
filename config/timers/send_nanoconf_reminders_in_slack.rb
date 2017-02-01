Houston.config.every "wednesday at 1:00pm", "announce:upcoming-nanoconf" do
  nanoconf = Nanoconf.next_for_this_week
  next unless nanoconf
  slack_send_message_to "Nanoconf this Friday will be", "it",
    attachments: [slack_nanoconf_attachment(nanoconf)]
end

Houston.config.every "friday at 12:30pm", "remind:upcoming-nanoconf" do
  nanoconf = Nanoconf.next_for_this_week
  next unless nanoconf
  slack_send_message_to "Just a reminder — Nanoconf starts in 30 minutes!", "it",
    attachments: [slack_nanoconf_attachment(nanoconf)]
end
