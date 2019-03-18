class ReportsController < ApplicationController
  layout "email"

  helper ReportsHelper
  helper Houston::Alerts::AlertHelper
  helper Houston::Engine.routes.url_helpers

  helper_method :stylesheets
  class_attribute :stylesheets
  self.stylesheets = %w{
    houston/core/colors.scss.erb
    houston/core/scores.scss
    houston/application/emoji.scss
  }

  self.stylesheets = stylesheets + %w{reports/charts.scss}

  def default
    @title = "Reports"
    render layout: "naked"
  end

  def star2
    fail CanCan::AccessDenied unless EP_DEVELOPERS.member?(current_user.email)
    @title = "Star"
    render layout: "naked"
  end

  def user_report
    date = Date.parse(params[:date]) rescue Date.today
    user = User.find_by_nickname! params[:nickname]
    authorize! :edit, user
    @report = WeeklyUserReport.new(user, date)
  end

  def weekly_report
    @title = "Weekly Report"
    date = Date.parse(params[:date]) rescue 1.day.ago

    @week = week_for_date(date)

    # Alerts due during this week
    # except for those that aren't closed
    # and still have time (i.e. due after today)
    #
    # so:
    #
    # Alerts due during this week
    # which were either closed or past-due
    #
    alerts = Houston::Alerts::Alert.arel_table
    @alerts_due = Houston::Alerts::Alert.where(deadline: @week)
      .where(
        alerts[:closed_at].not_eq(nil).or(
        alerts[:deadline].lteq(Time.now)))
    @alerts_rate = @alerts_due.select(&:on_time?).count * 100.0 / @alerts_due.count if @alerts_due.any?

    @alerts_closed_not_due = Houston::Alerts::Alert.where(closed_at: @week)
      .where(alerts[:deadline].lt(@week.begin))

    @alerts_opened_closed = ActiveRecord::Base.connection.select_all <<-SQL
      SELECT
        "days"."day",
        ( SELECT COUNT(*) FROM alerts
          WHERE opened_at::date = days.day
          AND destroyed_at IS NULL
        ) "alerts_opened",
        ( SELECT COUNT(*) FROM alerts
          WHERE closed_at::date = days.day
          AND destroyed_at IS NULL
        ) "alerts_closed"
      FROM generate_series('#{2.days.before(@week.begin)}'::date, '#{@week.end}'::date, '1 day') AS days(day)
      ORDER BY days.day ASC
    SQL

    render layout: "naked"
  end

  def star
    @title = "Time-Entry Dashboard"
    date = Date.parse(params[:date]) rescue Date.today
    @report = WeeklyGoalReport.new(date)

    @date_range = (date - 14)..date
    @measurements = Measurement \
      .named("daily.hours.{charged,worked,off}")
      .taken_on(@date_range)
      .includes(:subject)
    render layout: request.xhr? ? false : "instance_dashboard"
  end



  def star_export_by_component
    authorize! :admin, User
    since = params.fetch(:since, "2015-01-01").to_date
    subject = User
    subject = User.find_by_nickname! params[:nickname] if params[:nickname]
    bin = params.fetch(:bin, "daily")

    measurements = Measurement
      .for(subject)
      .named("#{bin}.hours.charged.*")
      .taken_since(since)

    prefix = "#{bin}.hours.charged."
    measurements_by_component = measurements.group_by do |measurement|
      component = measurement.name[prefix.length..-1]
      component = "itsm/exception/cve" if %w{itsm exception cve}.member? component
      component
    end
    measurements_by_component.delete "percent"
    dates = measurements.map(&:taken_on).uniq.reverse.reject { |date| date.wday == 0 || date.wday == 6 }

    package = OpenXml::Xlsx::Package.new
    worksheet = package.workbook.worksheets[0]

    worksheet.add_row(
      number: 2,
      cells: dates.each_with_index.map { |date, j|
        { column: j + 3, value: date, style: TIMESTAMP } } + [
        { column: dates.length + 3, value: "total", style: HEADING_R },
        { column: dates.length + 4, value: "percent", style: HEADING_R }
      ])

    last_column = column_letter(dates.length + 2)
    total_column = column_letter(dates.length + 3)

    measurements_by_component.each_with_index do |(component, measurements), i|
      worksheet.add_row(
        number: i + 3,
        cells: [
          { column: 2, value: component, style: HEADING }
        ] + dates.each_with_index.map { |date, j|
          value = measurements
            .find_all { |measurement| measurement.taken_on? date }
            .map { |measurement| measurement.value.to_d }
            .sum
          { column: j + 3, value: value, style: NUMBER }
        } + [
          { column: dates.length + 3, formula: "SUM(C#{i + 3}:#{last_column}#{i + 3})", style: NUMBER },
          { column: dates.length + 4, formula: "=#{total_column}#{i + 3}/#{total_column}#{measurements_by_component.length + 3}", style: PERCENT },
          { column: dates.length + 5, formula: "=B#{i + 3}", style: HEADING }
        ])
    end

    worksheet.add_row(
      number: measurements_by_component.length + 3,
      cells: [
        { column: 2, value: "total", style: HEADING }
      ] + dates.each_with_index.map { |date, j|
        column = column_letter(j + 3)
        { column: j + 3, formula: "SUM(#{column}3:#{column}#{measurements_by_component.length + 2})", style: NUMBER }
      } + [
        { column: dates.length + 3, formula: "SUM(#{total_column}3:#{total_column}#{measurements_by_component.length + 2})", style: NUMBER }
      ])

    worksheet.column_widths({1 => 3.83203125})

    send_data package.to_stream.string,
      type: :xlsx,
      filename: "Star Time for #{subject.name}.xlsx",
      disposition: "attachment"
  end



  def star_export_chargeable
    authorize! :admin, User
    since = params.fetch(:since, "2015-01-01").to_date
    subject = User
    subject = User.find_by_nickname! params[:nickname] if params[:nickname]
    bin = params.fetch(:bin, "daily")

    measurements = Measurement
      .for(subject)
      .named("#{bin}.hours.charged.percent")
      .taken_since(since)
      .preload(:subject)
    dates = measurements.map(&:taken_on).uniq.reverse.reject { |date| date.wday == 0 || date.wday == 6 }

    package = OpenXml::Xlsx::Package.new
    worksheet = package.workbook.worksheets[0]

    worksheet.add_row(
      number: 2,
      cells: dates.each_with_index.map { |date, j|
        { column: j + 3, value: date, style: TIMESTAMP } })

    last_column = column_letter(dates.length + 2)

    measurements_by_user = measurements.group_by(&:subject)
    measurements_by_user.each_with_index do |(user, measurements), i|
      worksheet.add_row(
        number: i + 3,
        cells: [
          { column: 2, value: user.name, style: HEADING }
        ] + dates.each_with_index.map { |date, j|
          value = measurements
            .find_all { |measurement| measurement.taken_on? date }
            .map { |measurement| measurement.value.to_d }
            .sum
          { column: j + 3, value: value, style: PERCENT } })
    end

    worksheet.column_widths({1 => 3.83203125})

    send_data package.to_stream.string,
      type: :xlsx,
      filename: "Star Time since #{since}.xlsx",
      disposition: "attachment"
  end


  def alerts
    @title = "Alerts Report"
    @date_range = Date.new(2015, 1, 1)..Date.today

    # Align @date_range to weeks
    @date_range = @date_range.begin.beginning_of_week..(6.days.after(@date_range.end.beginning_of_week))

    @project_id = params.fetch(:project_id, "-1") # -1 is all projects
    @user_id = params.fetch(:user_id, "-1") # -1 is everyone

    @projects = Project.where(Project.arel_table[:id].in(
      Houston::Alerts::Alert.arel_table.project(:project_id)))
    @users = User.where(User.arel_table[:id].in(
      Houston::Alerts::Alert.arel_table.project(:checked_out_by_id)))

    alerts = Houston::Alerts::Alert.reorder(nil).select("COUNT(*)")
    alerts = alerts.where(project_id: @project_id) unless @project_id == "-1"
    alerts = alerts.where(checked_out_by_id: @user_id) unless @user_id == "-1"

    types = alerts.pluck("DISTINCT type")

    @alerts_due_on_time_by_type = types.each_with_object({}) do |type, hash|
      _alerts = alerts.where(type: type)
        .where("deadline BETWEEN weeks.start AND (weeks.start + '1 week'::interval)")
      hash[type] = ActiveRecord::Base.connection.select_all <<-SQL
        SELECT
          ("weeks"."start" + '1 week'::interval) "week",
          (#{_alerts.to_sql}) "due",
          (#{_alerts.closed_on_time.to_sql}) "on_time"
        FROM generate_series('#{@date_range.begin}'::date, '#{@date_range.end}'::date, '1 week') AS weeks(start)
        ORDER BY weeks.start ASC
      SQL
    end

    render layout: "naked"
  end


private

  def column_letter(number)
    bytes = []
    remaining = number
    while remaining > 0
      bytes.unshift (remaining - 1) % 26 + 65
      remaining = (remaining - 1) / 26
    end
    bytes.pack "c*"
  end

  def week_for_date(date)
    start_date = date.beginning_of_week
    end_date = start_date.next_day
    end_date = end_date.next_day while !end_date.friday?

    start_date.beginning_of_day..end_date.end_of_day
  end


  HEADING = {
    alignment: OpenXml::Xlsx::Elements::Alignment.new("left", "center") }
  HEADING_R = {
    alignment: OpenXml::Xlsx::Elements::Alignment.new("right", "center") }
  GENERAL = {
    alignment: OpenXml::Xlsx::Elements::Alignment.new("left", "center") }
  TIMESTAMP = {
    format: OpenXml::Xlsx::Elements::NumberFormat::DATE,
    alignment: OpenXml::Xlsx::Elements::Alignment.new("right", "center") }
  PERCENT = {
    format: OpenXml::Xlsx::Elements::NumberFormat::INTEGER_PERCENT,
    alignment: OpenXml::Xlsx::Elements::Alignment.new("right", "center") }
  NUMBER = {
    alignment: OpenXml::Xlsx::Elements::Alignment.new("right", "center") }

end
