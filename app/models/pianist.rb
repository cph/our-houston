class Pianist < ActiveRecord::Base
  belongs_to :user

  default_scope { order(:year, :month) }

  class << self
    def for(date)
      where(year: date.year, month: date.month)
    end

    def upcoming
      now = Date.today
      where(arel_table[:year].gt(now.year))
        .or(where(year: now.year).and(where(arel_table[:month].gteq(now.month))))
    end
  end

end
