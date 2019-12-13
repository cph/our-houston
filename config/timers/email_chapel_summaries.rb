Houston.config.every "monday at 10am", "reminders:upcoming-chapel-summary" do
  upcoming = Presentation::ChapelService.next_within_a_week
  next unless upcoming
  upcoming.send_summary! unless upcoming.summary_sent?
end
