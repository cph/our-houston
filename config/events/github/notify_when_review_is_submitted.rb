Houston.config do
  negative_reactions = %w{:fearful: :hushed: :scream: :no_mouth: :worried: :anguished:}

  on "github:pull:reviewed:approved" => "github:slack-when-a-pull-request-is-approved" do
    pull_request.project.repo.remove_label_from("review-needed", pull_request) if pull_request.labeled?("review-needed")
    pull_request.project.repo.remove_label_from("review-hold", pull_request) if pull_request.labeled?("review-hold")
    pull_request.project.repo.add_label_to("review-pass", pull_request)

    message = ":tada: #{slack_link_to_pull_request(pull_request)} passed code review"
    message << " (#{pull_request.user.slack_username})" if pull_request.user && pull_request.user.slack_username
    slack_send_message_to message, "#code-review"
  end

  on "github:pull:reviewed:changes_requested" => "github:slack-when-a-pull-request-is-held" do
    pull_request.project.repo.remove_label_from("review-needed", pull_request) if pull_request.labeled?("review-needed")
    pull_request.project.repo.remove_label_from("review-pass", pull_request) if pull_request.labeled?("review-pass")
    pull_request.project.repo.add_label_to("review-hold", pull_request)

    message = "#{negative_reactions.sample} #{slack_link_to_pull_request(pull_request)} is being held by code review"
    message << " (#{pull_request.user.slack_username})" if pull_request.user && pull_request.user.slack_username
    slack_send_message_to message, "#code-review"
  end

end
