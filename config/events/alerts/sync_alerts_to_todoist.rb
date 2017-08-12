Houston.config do
  action "alert:sync-to-todoist", %w{alert} do
    sync_alert_to_todoist alert
  end

  on "alert:create" => "alert:sync-to-todoist"
  on "alert:update" => "alert:sync-to-todoist"
end
