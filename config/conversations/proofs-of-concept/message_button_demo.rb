Houston::Conversations.config do
  listen_for "show me how message buttons could work" do |e|
    e.reply "ok!", attachments: [{
      text: "A certain pull request is ready to merge",
      fallback: "A certain pull request is ready to merge",
      color: "good",
      callback_id: "demo",
      actions: [{
        name: "merge",
        text: "Merge",
        type: "button",
        style: "primary"
      }]
    }]
  end
end

Houston::Slack.config do
  action "demo:merge" do |e|
    original_message = e.original_message.dup
    attachment = original_message["attachments"][e.attachment_index]
    attachment.delete "actions"
    attachment["text"] << "\n:white_check_mark: *Merged!*"
    e.respond!(original_message.merge(replace_original: true))
  end
end
