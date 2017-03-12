Houston::Conversations.config do
  listen_for "show me how oauth could work" do |e|
    authorization = e.user.authorizations.create!({
      type: "Office365",
      scope: "offline_access https://outlook.office.com/calendars.read"
    })
    e.reply "Alright, I'll need access to your Office365 account.\nTo grant it, click here: #{authorization.url}"
    trigger = e.user.triggers.on("authorization:grant", "oauth-example:granted", channel: e.channel.to_s)
    trigger.save!
  end
end

Houston.config do
  action "oauth-example:granted", %w{authorization channel trigger} do
    slack_send_message_to ":white_check_mark: Thanks!", channel
    trigger.destroy
  end
end
