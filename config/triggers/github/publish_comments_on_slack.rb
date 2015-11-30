Houston.config do
  on "github:comment:commit" do |comment|
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers-only" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["commit_id"][0...7], url)}"

    slack_send_message_to message, channel, as: :github,
      attachments: [slack_github_comment_attachment(body)]
  end

  on "github:comment:diff" do |comment|
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers-only" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["path"], url)}"

    slack_send_message_to message, channel, as: :github,
      attachments: [slack_github_comment_attachment(body)]
  end

  on "github:comment:pull" do |comment|
    channel = "##{comment["project"].slug}" if comment["project"]
    channel = "developers-only" unless Houston::Slack.connection.channels.include? channel
    body, url = comment.values_at "body", "html_url"

    issue = comment["issue"]
    message = "#{comment["user"]["login"]} commented on #{slack_link_to("##{issue["number"]} #{issue["title"]}", url)}"

    slack_send_message_to message, channel, as: :github,
      attachments: [slack_github_comment_attachment(body)]
  end
end
