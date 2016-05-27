OUTLOOK_ENDPOINT = "https://outlook.office365.com/EWS/Exchange.asmx".freeze

class OutlookCalendar
  Event = Struct.new(:name, :time) do
    CARDINALS_DAY = /cardinal'?s? casual/i.freeze
    FOR_A_CAUSE_DAY = /casual for a cause/i.freeze
    BLUES_DAY = /blues casual/i.freeze
    EMPLOYEE_APPRECIATION_DAY = /employee (appreciation|activity)/i.freeze
    CASUAL_DAYS = %i{cardinals_casual_day blues_casual_day employee_appreciation_day}

    def recognize
      case name
      when CARDINALS_DAY then :cardinals_casual_day
      when BLUES_DAY then :blues_casual_day
      when FOR_A_CAUSE_DAY then :casual_for_a_cause
      when EMPLOYEE_APPRECIATION_DAY then :employee_appreciation_day
      else nil
      end
    end

    def date
      time.to_date
    end

    def casual?
      CASUAL_DAYS.member? recognize
    end
  end

  def self.cphevents
    @cphevents ||= begin
      outlook = Viewpoint::EWSClient.new(
        OUTLOOK_ENDPOINT,
        ENV["HOUSTON_OUTLOOK_EMAIL"],
        ENV["HOUSTON_OUTLOOK_PASSWORD"])
      self.new(outlook.get_folder(:calendar, act_as: "cphevents@cph.org"))
    end
  end

  def initialize(events)
    @events = events
  end

  # The range is inclusive
  def events_between(start_date, end_date)
    # 1. The range is exclusive; and we look ahead 2 days in order to find
    #    all-day events that end on the second day (UTC, at least).
    # 2. We convert .to_time before .to_date in order to convert the event's
    #    start time from UTC to local before truncating it to the date.
    # 3. We finally return only the events we care about.
    @events.items_between(start_date, end_date + 2).map do |event|
      name = event.subject
      start = event.start
      Event.new(name, start.to_time)
    end.select do |event|
      event.date >= start_date && event.date <= end_date
    end
  end
  alias :between :events_between

  def on(date)
    between(date, date)
  end

end
