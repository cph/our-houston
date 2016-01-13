Houston.config do
  on "feedback:comment:create" do |comment|
    project_channel = "##{comment.project.slug}"
    next unless Houston::Slack.connection.channels.include? project_channel

    lines = comment.text.split(/\n/)

    # Replace H_ tags with bold text of the same font size
    # and get rid of inner quotes.
    lines = lines.map do |line|
      line.strip
        .gsub(/^#+\s*(.*)$/m, "*\\1*") # replace H_ tags with bold text
        .gsub(/^>\s*/m, "") # get rid of inner quotes
        .gsub(/\*{2}/, "*") # it takes only one * to bold things in Slack
        .gsub(/\!\[.*\]\(([^)]+)\)/, "\\1") # clean up images
    end
    attribution = comment.attributed_to
    attribution = comment.customer.name if comment.customer
    if comment.user
      if attribution.nil?
        attribution = comment.user.name
      else
        attribution << " (entered by #{comment.user.name})"
      end
    end
    lines.push "    — #{attribution}" if attribution
    message = lines.map { |line| "> #{line}\n" }.join
      .gsub(/> \n> \n/m, "> \n")
      .gsub(/^(> \*.*\*\n)> \n(?!> \*)/m, "\\1")

    slack_send_message_to message, project_channel
  end
end
