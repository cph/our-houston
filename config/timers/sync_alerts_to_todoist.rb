Houston.config.every "10m", "sync:alerts-and-todoist" do
  alerts = Houston::Alerts::Alert.arel_table
  time = 6.days.ago
  Houston::Alerts::Alert.where(
    alerts[:opened_at].gteq(time).or(
    alerts[:closed_at].gteq(time))
  ).each do |alert|
    sync_alert_to_todoist(alert)
  end
end
