Houston::Conversations.config do
  listen_for "is it a casual day {{date:core.date.future}}",
             "is it a casual day",
             "is {{date:core.date.future}} a casual day" do |e|

    date = e.matched?("date") ? e.match["date"] : Date.today

    e.responding
    case CasualDay.check(date)
    when :cardinals_casual_day
      e.reply "Yep! It's a Cardinals Casual Day :+1:"
    when :blues_casual_day
      e.reply "Yep! It's a Blues Casual Day :+1:"
    when :casual_for_a_cause
      e.reply "It's a _Casual for a Cause_ Day"
    when :employee_appreciation_day
      e.reply "Yep! It's an Employee Appreciation Day :tada:"
    when :other_casual_day
      e.reply "Yep! It's a Casual Day :+1:"
    else
      e.reply "Well... it's not on the *CPH Events* calendar... :confused:"
    end
  end
end

Houston::Conversations.config do
  listen_for "when is the next casual day",
             "how long is it until the next casual day",
             "how long until the next casual day",
             "when can I wear jeans again" do |e|

    e.responding
    event = CasualDay.next
    case event && event.recognize
    when :cardinals_casual_day
      e.reply "#{event.time.strftime('%A (%-m/%-d)')} is a Cardinals Casual Day"
    when :blues_casual_day
      e.reply "#{event.time.strftime('%A (%-m/%-d)')} is a Blues Casual Day"
    when :casual_for_a_cause
      e.reply "#{event.time.strftime('%A (%-m/%-d)')} is a _Casual for a Cause_ Day"
    when :employee_appreciation_day
      e.reply "#{event.time.strftime('%A (%-m/%-d)')} is an Employee Appreciation Day"
    when :other_casual_day
      e.reply "#{event.time.strftime('%A (%-m/%-d)')} is a Casual Day"
    else
      e.reply "I don't know! :anguished:"
    end
  end
end
