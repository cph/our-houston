module Presentation
  class Base < ActiveRecord::Base
    self.table_name = "houston_presentations"

    scope :any_tags, -> (tags){ where('tags && ARRAY[?]', tags) }
    scope :all_tags, -> (tags){ where('tags @> ARRAY[?]', tags) }

    belongs_to :presenter, class_name: "User"

    def self.upcoming
      where(arel_table[:date].gteq(Date.today))
    end

    def self.next
      upcoming.order(date: :asc).first
    end

    def self.next_for_this_week
      upcoming.where(arel_table[:date].lt(Date.today.end_of_week))
              .order(date: :asc)
              .first
    end

    def self.next_within_a_week
      upcoming.where(arel_table[:date].lt(Date.today + 7.days)
        .order(date: :asc)
        .first
    end

    def past?
      date < Date.today
    end

  end
end
