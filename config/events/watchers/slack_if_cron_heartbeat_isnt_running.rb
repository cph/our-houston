Houston.config.on "watcher:success" => "watcher:notify-if-cron_inactive" do
  return unless checkin.project.slug == "ledger"

  last_checkin = Time.parse(checkin.info["last_checkin"])
  return unless Time.now - 40.minutes > last_checkin

  message = "*WARNING:* The cron job for #{checkin.project.name} last checked in at #{last_checkin}. Attn. @channel"
  slack_send_message_to message, "ep-developers"
end
