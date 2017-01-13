module Nanoconfs
  class Presentation < ActiveRecord::Base

    self.table_name = "nanoconf_presentations"
    scope :any_tags, -> (tags){where('tags && ARRAY[?]', tags)}
    scope :all_tags, -> (tags){where('tags @> ARRAY[?]', tags)}

    belongs_to :presenter, class_name: "User"

    def past?
      date < Date.today
    end
  end
end
