Houston.config do

  # Notify when a Pull Request passes or fails testing or review
  on "github:pull:label-added" do |pr, label|
    next unless label =~ /(test|review)-(pass|hold)/

    channel = ($1 == "test") ? "#testing" : "#code-review"
    verb = ($2 == "pass") ? "passed" : "is being held by"
    object = channel[1..-1].gsub("-", " ")
    message = "#{slack_link_to_pull_request(pr)} #{verb} #{object}"
    message = "#{pr.user.slack_username}, #{message}" if pr.user && pr.user.slack_username
    slack_send_message_to message, channel
  end


  # Notify when a Pull Request is ready for review
  on "github:pull:label-added" do |pr, label|
    next unless label == "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pr)} is ready for review"
    slack_send_message_to message, "#code-review"
  end

  on "github:pull:opened" do |pr|
    next unless pr.labeled? "review-needed"
    message = ":star2: #{slack_link_to_pull_request(pr)} is ready for review"
    slack_send_message_to message, "#code-review"
  end

end
