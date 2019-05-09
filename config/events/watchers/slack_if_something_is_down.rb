Houston.config.on "watcher:fail" => "watcher:slack-alerts-on-down" do
  last_status = Houston::Watcher::Checkin.where.not(id: checkin.id)
    .order(created_at: :desc)
    .limit(1)
    &.status
  next unless last_status.nil? || last_status == 200

  message = "Heads up, @channel! The check on #{checkin.product.name} failed at #{checkin.created_at} with status code #{checkin.status}"
  slack_send_message_to message, "ops"
end

Houston.config.on "watcher:success" => "watcher:slack-alerts-on-back-up" do
  last_status = Houston::Watcher::Checkin.where.not(id: checkin.id)
    .order(created_at: :desc)
    .limit(1)
    &.status
  next if last_status.nil? || last_status == 200

  message = "You can relax, @channel. The check on #{checkin.product.name} at #{checkin.created_at} succeeded"
  slack_send_message_to message, "ops"
end
