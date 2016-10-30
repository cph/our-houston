class WeeklyGoalReport < WeeklyReport


  { sprint: [ :sprint_intended, :sprint_completed, :sprint_rate, :sprint_rate_target,
              :sprints, :sprints_completed, :sprints_completed_target, :sprint_week_status,
              :sprint_quarter_status ],

    alerts: [ :alerts_closed, :alerts_rate, :alerts_rate_target, :alerts_rate_average,
              :alerts_week_status, :alerts_average_status ]

  }.each do |module_name, value_names|
    value_names.each do |value_name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{value_name}
        calculate_#{module_name}_values! unless defined?(@#{value_name})
        @#{value_name}
      end
      RUBY
    end
  end


private


  def calculate_sprint_values!
    @sprint_intended = measurements.named("weekly.sprint.effort.intended").total
    @sprint_completed = measurements.named("weekly.sprint.effort.completed").total
    @sprint_rate = @sprint_completed / @sprint_intended unless @sprint_intended.zero?
    @sprint_rate ||= 0
    @sprint_rate_target = 1

    completion_by_date = Hash[Measurement.where(taken_on: quarter.select { |date| date <= @date })
      .named("weekly.sprint.completed")
      .pluck(:taken_on, "value='1'")]
    @sprints = quarter.map { |date| completion_by_date[date] }
    @sprints_completed = @sprints.grep(TrueClass).count
    @sprints_completed_target = {"Q1" => 5, "Q2" => 6, "Q3" => 7}[quarter_name]

    @sprint_week_status = @sprint_intended.zero? ? "no-data" : @sprint_rate >= @sprint_rate_target ? "success" : "failure"
    @sprint_quarter_status = @sprints_completed_target && @sprints_completed >= @sprints_completed_target ?  "success" : "no-data"
  end

  def calculate_alerts_values!
    @alerts_closed = (measurements.global.named("weekly.alerts.completed").value || 0).to_d
    @alerts_rate = (measurements.global.named("weekly.alerts.due.completed-on-time.percent").value || 0).to_d
    @alerts_rate_target = 0.8

    total_alerts_due = Measurement.global.named("weekly.alerts.due").taken_between(january1, date).total
    total_alerts_on_time = Measurement.global.named("weekly.alerts.due.completed-on-time")
      .taken_between(january1, date).total
    @alerts_rate_average = total_alerts_due.zero? ? 0 : (total_alerts_on_time.to_f  / total_alerts_due)

    @alerts_week_status = @alerts_closed.zero? ? "no-data" : @alerts_rate >= @alerts_rate_target ? "success" : "failure"
    @alerts_average_status = @alerts_closed.zero? ? "no-data" : @alerts_rate_average >= @alerts_rate_target ? "success" : "failure"
  end


end
