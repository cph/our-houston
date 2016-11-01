Houston.config do
  negative_reactions = %w{:fearful: :hushed: :scream: :no_mouth: :worried: :anguished:}

  # Notify when a Pull Request passes or fails testing or review
  on "github:pull:label-added" => "github:slack-when-a-pull-request-passes-or-fails-testing-or-review" do
    next unless label =~ /test-(pass|hold)/

    emojis, verb = ($1 == "pass") ? [[":tada:"], "passed"] : [negative_reactions, "is being held by"]
    message = "#{emojis.sample} #{slack_link_to_pull_request(pull_request)} #{verb} testing"
    message << " (#{pull_request.user.slack_username})" if pull_request.user && pull_request.user.slack_username
    slack_send_message_to message, "#testing"
  end


  # Notify when a Pull Request is ready for review
  on "github:pull:label-added" => "github:slack-when-a-pull-request-is-ready-for-review" do
    # TODO: if this can be `next unless pr.labeled? "review-needed"`, these two can be merged into one action
    next unless label == "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pull_request)} is ready for review"
    slack_send_message_to message, "#code-review"
  end

  on "github:pull:opened" => "github:slack-when-a-new-pull-request-is-ready-for-review" do
    next unless pull_request.labeled? "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pull_request)} is ready for review"
    slack_send_message_to message, "#code-review"
  end

end
