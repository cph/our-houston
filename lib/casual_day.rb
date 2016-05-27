require_relative "outlook_calendar"

class CasualDay

  def self.check(date)
    event = OutlookCalendar.cphevents.on(date).find(&:casual?)
    event && event.recognize
  end

  def self.next
    today = Date.today

    # if the workday has started, look afterwards
    today += 1 if Time.now.hour > 9

    OutlookCalendar.cphevents.between(today, today + 31)
      .select(&:casual?)
      .sort_by(&:date)
      .first
  end

end
