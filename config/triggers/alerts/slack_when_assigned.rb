Houston.config do
  on "alert:assign" do |alert|
    if alert.checked_out_by && alert.updated_by && alert.checked_out_by != alert.updated_by
      Rails.logger.info "\e[34m[slack] #{alert.type} assigned to \e[1m#{alert.checked_out_by.first_name}\e[0m"

      message = [
        alert.updated_by.first_name,
        "assigned",
        alert_unfurl_url(alert),
        "to you"].join(" ")

      slack_send_message_to message, alert.checked_out_by
    end
  end
end
