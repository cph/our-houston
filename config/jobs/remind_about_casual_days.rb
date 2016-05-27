Houston.config.at "2:58pm", "announce:casual-days" do
  casual_day_type = case CasualDay.check(Date.today + 1)
  when :cardinals_casual_day then "a Cardinals Casual Day"
  when :blues_casual_day then "a Blues Casual Day"
  when :casual_for_a_cause then "a _Casual for a Cause_ Day"
  when :employee_appreciation_day then "an Employee Appreciation Day"
  end

  if casual_day_type
    slack_send_message_to "Don't forget, tomorrow is #{casual_day_type}!", "#general"
  end
end
