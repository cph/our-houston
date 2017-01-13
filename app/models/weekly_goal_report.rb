class WeeklyGoalReport < WeeklyReport


  { alerts: [ :alerts_closed, :alerts_rate, :alerts_rate_target, :alerts_rate_average,
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
