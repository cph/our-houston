# TODO: move this to a table in the database
# TODO: allow Houston instances to be Rails Engines so I can define a model here, for example
$comments_posted_on_slack = {}

Houston.config do
  on "github:comment:commit:create" => "github:slack-when-commit-comment-created" do
    body, url = comment.values_at "body", "html_url"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["commit_id"][0...7], url)}"
    response = slack_send_message_to message, "#code-review", as: :github,
      attachments: [slack_github_comment_attachment(body)]
    $comments_posted_on_slack[url] = response["ts"] if response["ok"]
  end

  on "github:comment:diff:create" => "github:slack-when-diff-comment-created" do
    body, url = comment.values_at "body", "html_url"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["path"], url)}"
    response = slack_send_message_to message, "#code-review", as: :github,
      attachments: [slack_github_comment_attachment(body)]
    $comments_posted_on_slack[url] = response["ts"] if response["ok"]
  end

  on "github:comment:pull:create" => "github:slack-when-pull-comment-created" do
    body, url, issue = comment.values_at "body", "html_url", "issue"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to("##{issue["number"]} #{issue["title"]}", url)}"
    response = slack_send_message_to message, "#code-review", as: :github,
      attachments: [slack_github_comment_attachment(body)]
    $comments_posted_on_slack[url] = response["ts"] if response["ok"]
  end



  on "github:comment:commit:update" => "github:slack-when-commit-comment-updated" do
    body, url = comment.values_at "body", "html_url"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["commit_id"][0...7], url)}"

    unless ts = $comments_posted_on_slack[url]
      Rails.logger.warn "\e[35mNo record of comment posted for #{url}\e[0m"
    end

    if ts.to_f < (Time.now.to_f - 900) # 15 minutes have passed
      Rails.logger.warn "\e[35mMore than 15 minutes has passed since #{url} was posted\e[0m"
      ts = nil
    end

    if ts
      slack_replace_message_on_channel ts, message, "#code-review", as: :github,
        attachments: [slack_github_comment_attachment(body)]
    else
      response = slack_send_message_to message, "#code-review", as: :github,
        attachments: [slack_github_comment_attachment(body)]
      $comments_posted_on_slack[url] = response["ts"] if response["ok"]
    end
  end

  on "github:comment:diff:update" => "github:slack-when-diff-comment-updated" do
    body, url = comment.values_at "body", "html_url"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to(comment["path"], url)}"

    unless ts = $comments_posted_on_slack[url]
      Rails.logger.warn "\e[35mNo record of comment posted for #{url}\e[0m"
    end

    if ts.to_f < (Time.now.to_f - 900) # 15 minutes have passed
      Rails.logger.warn "\e[35mMore than 15 minutes has passed since #{url} was posted\e[0m"
      ts = nil
    end

    if ts
      slack_replace_message_on_channel ts, message, "#code-review", as: :github,
        attachments: [slack_github_comment_attachment(body)]
    else
      response = slack_send_message_to message, "#code-review", as: :github,
        attachments: [slack_github_comment_attachment(body)]
      $comments_posted_on_slack[url] = response["ts"] if response["ok"]
    end
  end

  on "github:comment:pull:update" => "github:slack-when-pull-comment-updated" do
    body, url, issue = comment.values_at "body", "html_url", "issue"
    message = "#{comment["user"]["login"]} commented on #{slack_link_to("##{issue["number"]} #{issue["title"]}", url)}"

    unless ts = $comments_posted_on_slack[url]
      Rails.logger.warn "\e[35mNo record of comment posted for #{url}\e[0m"
    end

    if ts.to_f < (Time.now.to_f - 900) # 15 minutes have passed
      Rails.logger.warn "\e[35mMore than 15 minutes has passed since #{url} was posted\e[0m"
      ts = nil
    end

    if ts
      slack_replace_message_on_channel ts, message, "#code-review", as: :github,
        attachments: [slack_github_comment_attachment(body)]
    else
      response = slack_send_message_to message, "#code-review", as: :github,
        attachments: [slack_github_comment_attachment(body)]
      $comments_posted_on_slack[url] = response["ts"] if response["ok"]
    end
  end
end
