Houston.config do
  action "alert:notify-committers-that-alert-was-deployed", %w{alert} do
    user = alert.checked_out_by
    addressee, channel = user ? [user.first_name, user]: ["@group", "ep-developers"]

    message = [
      "Hey #{addressee},",
      slack_link_to(commit.sha[0...7], commit.url),
      "was just deployed to #{deploy.environment_name}.",
      "(Just letting you know in case that closes #{alert_unfurl_url(alert)})" ].join(" ")
    slack_send_message_to message, channel
  end

  on "alert:itsm:deployed" => "alert:notify-committers-that-alert-was-deployed"
  on "alert:zendesk:deployed" => "alert:notify-committers-that-alert-was-deployed"
end
