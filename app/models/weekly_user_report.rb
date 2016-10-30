class WeeklyUserReport < WeeklyGoalReport
  attr_reader :user, :username, :user_measurements

  def initialize(user, date)
    super date
    @user = user
    @username = user.nickname
    @user_measurements = measurements.for(user)
  end


  def team_measurements
    @team_measurements ||= measurements.global
  end


  def has_productivity_goal?
    user.id != 1 # Bob doesn't
  end


  { star:   [ :productivity_rate, :productivity_rate_target, :productivity_rate_average,
              :productivity_alerts_rate, :hours_charged_to_alerts, :productivity_week_status,
              :productivity_average_status ]

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


  def calculate_star_values!
    hours_worked = user_measurements.named("weekly.hours.worked").total
    @hours_charged_to_alerts = user_measurements.named("weekly.hours.charged.{cve,itsm,exception}").total
    unless hours_worked.zero?
      hours_charged = user_measurements.named("weekly.hours.charged").total
      @productivity_rate = hours_charged / hours_worked
      @productivity_alerts_rate = @hours_charged_to_alerts / hours_worked
    end
    @productivity_rate ||= 0
    @productivity_alerts_rate ||= 0
    @productivity_rate_target = 0.75 if has_productivity_goal?

    total_hours_worked = Measurement.for(@user).named("weekly.hours.worked").taken_between(january1, date).total
    total_hours_charged = Measurement.for(@user).named("weekly.hours.charged").taken_between(january1, date).total
    @productivity_rate_average = total_hours_worked.zero? ? 0 : (total_hours_charged.to_f  / total_hours_worked)

    @productivity_week_status = @productivity_rate_target.nil? || hours_worked.zero? ? "no-data" : @productivity_rate >= @productivity_rate_target ? "success" : "failure"
    @productivity_average_status = @productivity_rate_target.nil? || hours_worked.zero? ? "no-data" : @productivity_rate_average >= @productivity_rate_target ? "success" : "failure"
  end


end
