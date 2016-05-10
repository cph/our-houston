Houston::Slack.config do
  listen_for "is it a casual day {{date:relative-date}}",
             "is it a casual day",
             "is {{date:relative-date}} a casual day" do |e|

    date = e.matched?("date") ? e.match["date"] : Date.today

    case CasualDay.check(date)
    when :cardinals
      e.reply "Yep! It's a Cardinals Casual Day :+1:"
    when :blues
      e.reply "Yep! It's a Blues Casual Day :+1:"
    when :employee_appreciation
      e.reply "Yep! It's an Employee Appreciation Day :tada:"
    else
      e.reply "Well... it's not on the *CPH Events* calendar... :confused:"
    end
  end
end

Houston::Slack.config do
  listen_for "when is the next casual day",
             "how long is it until the next casual day",
             "how long until the next casual day",
             "when can I wear jeans again" do |e|

    event_type, event_time = CasualDay.next
    case event_type
    when :cardinals
      e.reply "#{event_time.strftime('%A (%-m/%-d)')} is a Cardinals Casual Day"
    when :blues
      e.reply "#{event_time.strftime('%A (%-m/%-d)')} is a Blues Casual Day"
    when :employee_appreciation
      e.reply "#{event_time.strftime('%A (%-m/%-d)')} is an Employee Appreciation Day"
    else
      e.reply "I don't know! :anguished:"
    end
  end
end
