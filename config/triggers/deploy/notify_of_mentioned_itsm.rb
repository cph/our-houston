Houston.config.on "alert:itsm:deployed" do |alert, deploy, commit|
  user = alert.checked_out_by
  addressee, channel = user ? [user.first_name, user]: ["@group", "developers"]

  message = [
    "Hey #{addressee},",
    slack_link_to(commit.sha[0...7], commit.url),
    "was just deployed to #{deploy.environment_name}.",
    "(Just letting you know in case that closes it.)" ].join(" ")
  slack_send_message_to message, channel,
    attachments: [slack_alert_attachment(alert)]
end
