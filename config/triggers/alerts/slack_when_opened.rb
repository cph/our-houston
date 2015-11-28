Houston.config do
  # Notify #alerts of new alerts
  on "alert:create" do |alert|
    message =  "There's a new #{alert.type}"
    message << " for *#{alert.project.slug}*" if alert.project
    message << ": #{alert_unfurl_url(alert)}"
    slack_send_message_to message, "#alerts"
  end
end
