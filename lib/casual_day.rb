OUTLOOK_ENDPOINT = "https://outlook.office365.com/EWS/Exchange.asmx".freeze
CARDINALS_DAY = /cardinal'?s? casual/i.freeze
APPRECIATION_DAY = /employee (appreciation|activity)/i.freeze

class CasualDay

  def self.check(date)
    # 1. The range is exclusive; and we look ahead 2 days in order to find
    #    all-day events that end on the second day (UTC, at least).
    # 2. We convert .to_time before .to_date in order to convert the event's
    #    start time from UTC to local before truncating it to the date.
    # 3. We only care about the names of the events.
    events = cphevents.items_between(date, date + 2)
      .select { |event| event.start.to_time.to_date == date }
      .map { |event| event.subject }

    if events.grep(CARDINALS_DAY).any?
      :cardinals
    elsif events.grep(APPRECIATION_DAY).any?
      :employee_appreciation
    else
      nil
    end
  end

  def self.next
    today = Date.today
    event = cphevents.items_between(today, today + 31)
      .select { |event| event.subject =~ CARDINALS_DAY || event.subject =~ APPRECIATION_DAY }
      .sort_by { |event| event.start.to_time.to_date }
      .first

    return nil unless event

    case event.subject
    when CARDINALS_DAY
      [:cardinals, event.start.to_time]
    when APPRECIATION_DAY
      [:employee_appreciation, event.start.to_time]
    else
      nil
    end
  end

  def self.cphevents
    @cphevents ||= begin
      outlook = Viewpoint::EWSClient.new(
        OUTLOOK_ENDPOINT,
        ENV["HOUSTON_OUTLOOK_EMAIL"],
        ENV["HOUSTON_OUTLOOK_PASSWORD"])
      outlook.get_folder(:calendar, act_as: "cphevents@cph.org")
    end
  end

end
