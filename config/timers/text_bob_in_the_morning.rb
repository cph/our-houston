Houston.config.at [:weekday, "5:45am"], "send-bob-morning-text" do
  date = Date.today
  messages = []

  casual_day_type = case CasualDay.check(date)
  when :cardinals_casual_day then "a Cardinals Casual Day"
  when :blues_casual_day then "a Blues Casual Day"
  when :casual_for_a_cause then "a _Casual for a Cause_ Day"
  when :employee_appreciation_day then "an Employee Appreciation Day"
  end
  messages << "Today is #{casual_day_type}" if casual_day_type

  menu = LunchMenu.for(date)
  messages << "The lunch menu is:\n#{menu.join("\n")}" if menu

  if messages.any?
    Houston::Twilio.send "Good Morning!\n\n#{messages.join("\n\n")}", to: "+16365419195"
  end
end
