Houston.config.every "friday at 6:00am", "report:weekly:developer" do
  date = Date.today - 1
  User.with_email_address(EP_DEVELOPERS).each do |user|
    report = Houston::Reports::WeeklyUserReport.new(user, date)
    Houston.try({max_tries: 3}, Net::OpenTimeout) do
      ReportsMailer.weekly_user_report(report, bcc: "bob.lail@cph.org").deliver!
    end
  end
end
