Houston.config do
  on "feedback:add" => "feedback:announce-in-slack" do
    project = conversation.project.slug
    feedback_channels = %W{#{project}-feedback ##{project}-feedback #{project} ##{project}}
    channel = feedback_channels.find { |channel| Houston::Slack.connection.can_see?(channel) }
    next unless channel

    # !! Copied from houston/feedback/conversations_controller.rb

    author = conversation.attributed_to
    if conversation.user
      author << " (#{conversation.user.name})" unless author.empty?
      author = conversation.user.name if author.empty?
    end

    lines = conversation.text.split(/\n/)

    # Replace H_ tags with bold text of the same font size
    # and get rid of inner quotes.
    lines = lines.map do |line|
      line.strip
        .gsub(/^#+\s*(.*)$/m, "*\\1*") # replace H_ tags with bold text
        .gsub(/^>\s*/m, "") # get rid of inner quotes
        .gsub(/\*{2}/, "*") # it takes only one * to bold things in Slack
        .gsub(/\!\[.*\]\(([^)]+)\)/, "\\1") # clean up images
    end
    message = lines.join("\n").gsub(/\n+/m, "\n").strip

    result = slack_send_message_to nil, channel,
      attachments: [{
        author_name: "#{conversation.project.slug} feedback",
        title: author,
        text: message,
        footer: "#{conversation.created_at.strftime("%b %-e")} #{conversation.created_at.strftime("%l:%M%p").downcase}  |  #{slack_link_to("open in Houston", feedback_unfurl_url(conversation))}",
        mrkdwn_in: %w{text footer}
      }]

    conversation.update_prop!("slack.ts", conversation.props.fetch("slack.ts", []) + result.values_at("ts"))
  end
end
