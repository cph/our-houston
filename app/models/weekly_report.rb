class WeeklyReport
  attr_reader :date, :week

  def initialize(date)
    @date = to_thursday_on_or_after date
    @week = (@date - 6)..@date
  end

  def measurements
    @measurements ||= Measurement.where(taken_on: week).named("weekly.*")
  end

  def quarter_name
    @quarter_name ||= {1 => "Q1", 4 => "Q2", 7 => "Q3", 10 => "Q4"}.fetch(quarter[0].month)
  end

  def quarter
    # shift ahead 3 so that weeks that straddle a quarter are counted in the quarter
    # where most of their days occur
    @quarter ||= (to_thursday_on_or_after((date - 3).beginning_of_quarter + 3)..
                  to_thursday_on_or_before((date - 3).end_of_quarter + 3)).step(7).to_a
  end

  def to_thursday_on_or_after(date)
    days_until_thursday = 4 - date.wday
    days_until_thursday += 7 if days_until_thursday < 0
    date + days_until_thursday
  end

  def to_thursday_on_or_before(date)
    days_since_thursday = date.wday - 4
    days_since_thursday += 7 if days_since_thursday < 0
    date - days_since_thursday
  end

  def january1
    Date.new(date.year, 1, 1)
  end

end
