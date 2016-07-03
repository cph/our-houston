Houston.config do
  at "11:50pm", "measure:sprint", every: :thursday do
    measure_sprint_effort_for_week!
    measure_alerts_for_week!
  end

  every "1h", "measure:star" do
    measure_star_time!
  end

  at "6:30am", "measure:logs" do
    measure_log_files!
  end

  at "9:00am", "measure:alerts.open" do
    measure_open_alerts!
    measure_alerts_closed_on_time!(1.day.ago)
  end
end



# Benchmark.ms { (3..32).each { |i| measure_log_files! Date.today - i } }
# Benchmark.ms { (0..484).each { |i| measure_open_alerts! 9.hours.after(Date.today - i) } }
# Benchmark.ms { (0..484).each { |i| measure_alerts_closed_on_time! 9.hours.after(Date.today - i) } }

def measure_log_files!(date=Date.today - 2)
  taken_at = Time.zone.local(date.year, date.month, date.day)
  range = date.beginning_of_day.utc..date.end_of_day.utc
  requests = Logeater::Request.where(completed_at: range)

  %w{members unite ledger}.each do |project_slug|
    project = Project.find_by_slug project_slug
    app_requests = requests.where(app: project_slug)

    # Number of requests that day
    # Number of requests by HTTP status
    # Percent of requests that were errors
    total_requests = 0
    total_errors = 0
    app_requests.group(:http_status).pluck(:http_status, "COUNT(*)").each do |status, count|
      Measurement.take!(name: "daily.requests.#{status}", taken_at: taken_at, subject: project, value: count)
      total_requests += count
      total_errors += count if status >= 500
    end
    Measurement.take!(name: "daily.requests", taken_at: taken_at, subject: project, value: total_requests)

    if total_requests > 0
      Measurement.take!(name: "daily.requests.5xx.percent", taken_at: taken_at, subject: project, value:
        (total_errors.to_f / total_requests.to_f).round(6))
      Measurement.take!(name: "daily.requests.duration.mean", taken_at: taken_at, subject: project, value:
        app_requests.average(:duration).round(4))
      Measurement.take!(name: "daily.requests.duration.percentile.98", taken_at: taken_at, subject: project, value:
        app_requests.pluck("percentile_cont(0.98) within group (order by duration asc)")[0])
    end
  end
end

def measure_open_alerts!(taken_at=Time.now)
  Measurement.take!(name: "daily.alerts.open", taken_at: taken_at, value:
    Houston::Alerts::Alert.open(at: taken_at).count)
end

def measure_alerts_closed_on_time!(taken_at=Time.now)
  range = taken_at.beginning_of_day..taken_at.end_of_day
  alerts_due = Houston::Alerts::Alert.where(deadline: range)
  alerts_on_time = alerts_due.closed_on_time.count
  alerts_due = alerts_due.count
  Measurement.take!(name: "daily.alerts.due", taken_at: taken_at, value: alerts_due)
  Measurement.take!(name: "daily.alerts.due.completed-on-time", taken_at: taken_at, value: alerts_on_time)
  Measurement.take!(name: "daily.alerts.due.completed-on-time.percent", taken_at: taken_at,
    value: (alerts_on_time.to_f / alerts_due).round(4)) if alerts_due > 0
end



STAR_USERNAME_FOR_USER = {
  BEN => "GOVEROBT",
  BOB => "LAILRC",
  LUKE => "BOOTHJL",
  CHASE => "CLETTECA",
  MATT => "KOBSMC",
  RYAN => "SHEARP"
}.freeze


class TemporaryCredentials
  def with_credentials
    yield "Houston", ENV["HOUSTON_CPH_PASSWORD"]
  end
end


def to_end_of_thursday(time)
  days_until_thursday = 4 - time.wday
  days_until_thursday += 7 if days_until_thursday < 0
  days_until_thursday.days.from(time).end_of_day
end

def measure_star_time!(time=Time.now)
  # Find entries for the last 3 weeks
  taken_at = to_end_of_thursday(time)
  date = taken_at.to_date
  weeks = (-14..0).step(7).map { |ago| (date + (ago - 6))..(date + ago) }
  weeks.each do |week|
    measure_star_time_for_week!(week)
  end
end

def measure_star_time_for_year!
  now = Time.now
  measure_alerts_for_range!(Time.new(now.year, 1, 1)..now)
end

def measure_star_time_for_range!(range)
  taken_at = to_end_of_thursday(range.begin).to_date
  while taken_at < range.end
    week = (taken_at - 6)..taken_at
    measure_star_time_for_week!(week)
    taken_at = 7.days.after(taken_at)
  end
end

def measure_star_time_for_week!(week)
  star = Star.new(TemporaryCredentials.new)
  taken_at = week.end.to_time.end_of_day

  all_star_entries = STAR_USERNAME_FOR_USER.flat_map do |email, username|
    user = User.find_by_email(email)
    star_entries_for_week = []
    unitime_entries_for_week = []

    week.each do |date|
      star_entries = star.get_time!(date, username)
      unitime_entries = star.get_unitime!(date, username)
      record_star_measurements!(
        taken_at: date.to_time.end_of_day,
        user: user,
        prefix: "daily",
        star_entries: star_entries,
        unitime_entries: unitime_entries)
      star_entries_for_week.concat star_entries
      unitime_entries_for_week.concat unitime_entries
    end

    record_star_measurements!(
      taken_at: taken_at,
      user: user,
      prefix: "weekly",
      star_entries: star_entries_for_week,
      unitime_entries: unitime_entries_for_week)

    star_entries_for_week
  end

  all_star_entries.group_by { |attrs| attrs[:project] }.each do |project_slug, star_entries|
    project = Project.find_by_slug project_slug
    next unless project

    Measurement.take!(subject: project, taken_at: taken_at, name: "weekly.hours.charged",
      value: star_entries.sum { |attrs| attrs[:hours] })

    star_entries.group_by { |attrs| attrs[:component] }.each do |component, star_entries|
      Measurement.take!(subject: project, taken_at: taken_at, name: "weekly.hours.charged.#{component}",
        value: star_entries.sum { |attrs| attrs[:hours] })
    end
  end
end

def record_star_measurements!(taken_at: nil, user: nil, prefix: nil, star_entries: nil, unitime_entries: nil)
  hours_worked = unitime_entries.select { |attrs| attrs[:pay_code] == :regular }.sum { |attrs| attrs[:hours] }
  hours_off = unitime_entries.select { |attrs| [:timeoff, :holiday].member?(attrs[:pay_code]) }.sum { |attrs| attrs[:hours] }
  hours_charged = star_entries.sum { |attrs| attrs[:hours] }

  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.worked", value: hours_worked)
  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.off", value: hours_off)
  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.charged", value: hours_charged)
  Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.charged.percent",
    value: (hours_charged.to_f / hours_worked).round(4)) if hours_worked > 0

  star_entries.group_by { |attrs| attrs[:component] }.each do |component, star_entries|
    Measurement.take!(subject: user, taken_at: taken_at, name: "#{prefix}.hours.charged.#{component}",
      value: star_entries.sum { |attrs| attrs[:hours] })
  end
end





def measure_sprint_effort_for_week!(time=Time.now)
  taken_at = to_end_of_thursday(time)

  sprint = Sprint.find_by_date(taken_at)
  return unless sprint

  sprint.sprint_tasks.joins(:task)
    .group("sprints_tasks.checked_out_by_id")
    .pluck("sprints_tasks.checked_out_by_id", "SUM(tasks.effort)")
    .each do |(user_id, effort)|
      Measurement.take!(name: "weekly.sprint.effort.intended", taken_at: taken_at,
        subject_type: "User", subject_id: user_id, value: effort) if user_id
  end

  sprint.sprint_tasks.joins(:task)
    .completed_during(sprint)
    .group("sprints_tasks.checked_out_by_id")
    .pluck("sprints_tasks.checked_out_by_id", "SUM(tasks.effort)")
    .each do |(user_id, effort)|
      Measurement.take!(name: "weekly.sprint.effort.completed", taken_at: taken_at,
        subject_type: "User", subject_id: user_id, value: effort) if user_id
  end

  intended = sprint.sprint_tasks.joins(:task).sum("tasks.effort")
  completed = sprint.sprint_tasks.joins(:task).completed_during(sprint).sum("tasks.effort")
  Measurement.take!(name: "weekly.sprint.completed", taken_at: taken_at,
    value: intended == completed ? "1" : "0")
end



def measure_alerts_for_year!
  now = Time.now
  measure_alerts_for_range!(Time.new(now.year, 1, 1)..now)
end

def measure_alerts_for_range!(range)
  taken_at = to_end_of_thursday(range.begin)
  while taken_at < range.end
    measure_alerts_for_week!(taken_at)
    taken_at = 7.days.after(taken_at)
  end
end

def measure_alerts_for_week!(time=Time.now)
  taken_at = to_end_of_thursday(time)

  week = 6.days.before(taken_at).beginning_of_day..taken_at.end_of_day

  # Alerts Completed this Week
  alerts = Houston::Alerts::Alert.where(closed_at: week).includes(:checked_out_by)
  alerts.group_by(&:checked_out_by).each do |user, alerts|
    Measurement.take!(name: "weekly.alerts.completed", taken_at: taken_at, subject: user, value: alerts.count)
    alerts.group_by(&:type).each do |type, alerts|
      Measurement.take!(name: "weekly.alerts.completed.#{type}", taken_at: taken_at, subject: user, value: alerts.length)
    end
  end
  Measurement.take!(name: "weekly.alerts.completed", taken_at: taken_at, value: alerts.count)
  alerts.group_by(&:type).each do |type, alerts|
    Measurement.take!(name: "weekly.alerts.completed.#{type}", taken_at: taken_at, value: alerts.length)
  end

  # Alerts Opened this Week
  alerts = Houston::Alerts::Alert.where(opened_at: week).includes(:project)
  Measurement.take!(name: "weekly.alerts.opened", taken_at: taken_at, value: alerts.count)
  alerts.group_by(&:type).each do |type, alerts|
    Measurement.take!(name: "weekly.alerts.opened.#{type}", taken_at: taken_at, value: alerts.length)
  end
  alerts.group_by(&:project).each do |project, alerts|
    Measurement.take!(name: "weekly.alerts.opened", taken_at: taken_at, subject: project, value: alerts.count)
    alerts.group_by(&:type).each do |type, alerts|
      Measurement.take!(name: "weekly.alerts.opened.#{type}", taken_at: taken_at, subject: project, value: alerts.length)
    end
  end

  # Alerts Due this Week
  alerts = Houston::Alerts::Alert.where(deadline: week).includes(:checked_out_by) \
    .select { |alert| alert.deadline < week.end }

  alerts.group_by(&:checked_out_by).each do |user, alerts|
    if alerts.count > 0
      alerts_completed_on_time = alerts.select { |alert| alert.on_time?(week.end) != false }.count
      Measurement.take!(name: "weekly.alerts.due", taken_at: taken_at, subject: user,
        value: alerts.count)
      Measurement.take!(name: "weekly.alerts.due.completed-on-time", taken_at: taken_at, subject: user,
        value: alerts_completed_on_time)
      Measurement.take!(name: "weekly.alerts.due.completed-on-time.percent", taken_at: taken_at, subject: user,
        value: (alerts_completed_on_time.to_f / alerts.count).round(4))
    end
  end
  if alerts.count > 0
    alerts_completed_on_time = alerts.select { |alert| alert.on_time?(week.end) != false }.count.to_f
    Measurement.take!(name: "weekly.alerts.due", taken_at: taken_at,
      value: alerts.count)
    Measurement.take!(name: "weekly.alerts.due.completed-on-time", taken_at: taken_at,
      value: alerts_completed_on_time)
    Measurement.take!(name: "weekly.alerts.due.completed-on-time.percent", taken_at: taken_at,
      value: (alerts_completed_on_time.to_f / alerts.count).round(4))
  end
end

def get_time_records_for(user, during: nil)
  measurements = Measurement.for(user)
    .named("daily.hours.{charged,worked,off}")
    .taken_on(during)

  during.map do |date|
    charged = measurements.find { |m| m.taken_on?(date) && m.name == "daily.hours.charged" }.try(:value).to_s.to_d
    worked = measurements.find { |m| m.taken_on?(date) && m.name == "daily.hours.worked" }.try(:value).to_s.to_d
    off = measurements.find { |m| m.taken_on?(date) && m.name == "daily.hours.off" }.try(:value).to_s.to_d
    recorded = worked + off
    star_goal = (user.id == 1 ? 0.25 : 0.5) * worked
    empower_goal = 6.0

    { date: date,
      charged: charged,
      worked: worked,
      off: off,
      recorded: worked + off }
  end
end
