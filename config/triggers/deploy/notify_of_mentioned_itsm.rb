Houston.config.on "alert:itsm:deployed" do |alert, deploy, commit|
  user = alert.checked_out_by
  addressee, channel = user ? [user.first_name, user]: ["@group", "developers-only"]

  message = [
    "Hey #{addressee},",
    slack_link_to(commit.sha[0...7], commit.url),
    "was just deployed to #{deploy.environment_name}.",
    "(Just letting you know in case that closes #{alert_unfurl_url(alert)})" ].join(" ")
  slack_send_message_to message, channel
end
