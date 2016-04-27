OUTLOOK_ENDPOINT = "https://outlook.office365.com/EWS/Exchange.asmx".freeze
CARDINALS_DAY = /cardinal'?s? casual/i.freeze
APPRECIATION_DAY = /employee (appreciation|activity)/i.freeze

Houston::Slack.config do
  listen_for "is it a casual day {{date:relative-date}}",
             "is it a casual day",
             "is {{date:relative-date}} a casual day" do |e|

    outlook = Viewpoint::EWSClient.new(
      OUTLOOK_ENDPOINT,
      ENV["HOUSTON_OUTLOOK_EMAIL"],
      ENV["HOUSTON_OUTLOOK_PASSWORD"])

    cphevents = outlook.get_folder(:calendar, act_as: "cphevents@cph.org")

    date = e.matched?("date") ? e.match["date"] : Date.today

    # 1. The range is exclusive; and we look ahead 2 days in order to find
    #    all-day events that end on the second day (UTC, at least).
    # 2. We convert .to_time before .to_date in order to convert the event's
    #    start time from UTC to local before truncating it to the date.
    # 3. We only care about the names of the events.
    events = cphevents.items_between(date, date + 2)
      .select { |event| event.start.to_time.to_date == date }
      .map { |event| event.subject }

    if events.grep(CARDINALS_DAY).any?
      e.reply "Yep! It's a Cardinals Casual Day :+1:"
    elsif events.grep(APPRECIATION_DAY).any?
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

    outlook = Viewpoint::EWSClient.new(
      OUTLOOK_ENDPOINT,
      ENV["HOUSTON_OUTLOOK_EMAIL"],
      ENV["HOUSTON_OUTLOOK_PASSWORD"])

    cphevents = outlook.get_folder(:calendar, act_as: "cphevents@cph.org")

    today = Date.today
    event = cphevents.items_between(today, today + 31)
      .select { |event| event.subject =~ CARDINALS_DAY || event.subject =~ APPRECIATION_DAY }
      .sort_by { |event| event.start.to_time.to_date }
      .first

    unless event
      e.reply "I don't know! :anguished:"
      next
    end

    date = event.start.to_time
    case event.subject
    when CARDINALS_DAY
      e.reply "#{date.strftime('%A (%-m/%-d)')} is a Cardinals Casual Day"
    when APPRECIATION_DAY
      e.reply "#{date.strftime('%A (%-m/%-d)')} is an Employee Appreciation Day"
    end
  end
end
