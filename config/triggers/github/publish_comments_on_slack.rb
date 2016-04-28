Houston.config do
  on "github:comment:created:commit" do |comment|
    body, url = comment.values_at "body", "html_url"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["commit_id"][0...7], url)}"
    slack_send_message_to message, "#code-review", as: :github,
      attachments: [slack_github_comment_attachment(body)]
  end

  on "github:comment:created:diff" do |comment|
    body, url = comment.values_at "body", "html_url"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["path"], url)}"
    slack_send_message_to message, "#code-review", as: :github,
      attachments: [slack_github_comment_attachment(body)]
  end

  on "github:comment:created:pull" do |comment|
    body, url, issue = comment.values_at "body", "html_url", "issue"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to("##{issue["number"]} #{issue["title"]}", url)}"
    slack_send_message_to message, "#code-review", as: :github,
      attachments: [slack_github_comment_attachment(body)]
  end
end
