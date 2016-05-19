Houston.config.at "2:58pm", "announce:casual-days" do
  casual_day_type = case CasualDay.check(Date.today + 1)
  when :cardinals then "a Cardinals Casual Day"
  when :blues then "a Blues Casual Day"
  when :employee_appreciation then "an Employee Appreciation Day"
  end

  if casual_day_type
    slack_send_message_to "Don't forget, tomorrow is #{casual_day_type}!", "#general"
  end
end
