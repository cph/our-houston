require_relative "../../../lib/time_helpers"

Houston.config do
  on "alert:zendesk:reopen" => "alert:extend-deadline" do
    deadline = 1.day.from_now
    deadline = 2.days.after(deadline) if weekend?(deadline)
    alert.update_column :deadline, deadline
  end
end
