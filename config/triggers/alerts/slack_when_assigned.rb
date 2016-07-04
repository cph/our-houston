Houston.config do
  # Slack the person who was assigned the Alert
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

  # Slack everyone CCed on a Zendesk ticket to let them know who's working on it
  on "alert:zendesk:assign" do |alert|
    next unless alert.checked_out_by

    Array(alert.props["collaborator_ids"]).each do |zendesk_id|
      user = User.find_by_prop "zendesk.id", zendesk_id do |zendesk_id|
        response = MultiJson.load($zendesk.get("users/#{zendesk_id}").body)
        User.find_by_email_address response["user"]["email"] if response
      end
      next unless user

      Rails.logger.info "\e[34m[slack] Tell \e[1m#{user.first_name}\e[0;34m that #{alert.type} ##{alert.number} was assigned to \e[1m#{alert.checked_out_by.first_name}\e[0m"

      message = [
        "#{user.first_name},",
        alert.checked_out_by.first_name,
        "checked out",
        alert_unfurl_url(alert)
      ].join(" ")

      slack_send_message_to message, user
    end
  end
end
