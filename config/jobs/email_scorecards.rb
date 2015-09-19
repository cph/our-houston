Houston.config.at "6:00am", "report:weekly:developer", every: :friday do
  date = Date.today - 1
  User.with_email_address(FULL_TIME_DEVELOPERS).each do |user|
    report = Houston::Reports::WeeklyUserReport.new(user, date)
    Houston.try({max_tries: 3}, Net::OpenTimeout) do
      Houston::Reports::Mailer.weekly_user_report(report, bcc: "bob.lail@cph.org").deliver!
    end
  end
end
