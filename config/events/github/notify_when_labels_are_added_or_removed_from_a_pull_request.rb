Houston.config do
  negative_reactions = %w{:fearful: :hushed: :scream: :no_mouth: :worried: :anguished:}

  # Notify when a Pull Request passes or fails testing or review
  on "github:pull:label-added" => "github:slack-when-a-pull-request-passes-or-fails-testing-or-review" do
    next unless label =~ /(test|review)-(pass|hold)/

    pr = pull_request
    channel = ($1 == "test") ? "#testing" : "#code-review"
    emojis, verb = ($2 == "pass") ? [[":tada:"], "passed"] : [negative_reactions, "is being held by"]
    object = channel[1..-1].gsub("-", " ")
    message = "#{emojis.sample} #{slack_link_to_pull_request(pr)} #{verb} #{object}"
    message << " (#{pr.user.slack_username})" if pr.user && pr.user.slack_username
    slack_send_message_to message, channel
  end


  # Notify when a Pull Request is ready for review
  on "github:pull:label-added" => "github:slack-when-a-pull-request-is-ready-for-review" do
    # TODO: if this can be `next unless pr.labeled? "review-needed"`, these two can be merged into one action
    pr = pull_request
    next unless label == "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pr)} is ready for review"
    slack_send_message_to message, "#code-review"
  end

  on "github:pull:opened" => "github:slack-when-a-new-pull-request-is-ready-for-review" do
    pr = pull_request
    next unless pr.labeled? "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pr)} is ready for review"
    slack_send_message_to message, "#code-review"
  end

end
