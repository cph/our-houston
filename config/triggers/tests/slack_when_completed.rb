Houston.config do
  on "test_run:complete" do |test_run|
    # When branch is nil, the test run was requested by Houston
    # not triggered by a developer pushing changes to GitHub.
    next if test_run.branch.nil?
    next if test_run.aborted?

    nickname = test_run.user.slack_username if test_run.user
    project_slug = test_run.project.slug
    project_channel = "##{project_slug}"
    branch = "#{project_slug}/#{test_run.branch}"

    text = test_run.short_description(with_duration: true)
    text << "\n#{nickname}" if test_run.result != "pass" && nickname

    attachment = case test_run.result
    when "pass"
      { color: "#5DB64C",
        title: "All tests passed on #{branch}" }
    when "fail"
      { color: "#E24E32",
        title: "#{test_run.fail_count} #{test_run.fail_count == 1 ? "test" : "tests"} failed on #{branch}" }
    else
      { color: "#DFCC3D",
        title: "The tests are broken on #{branch}" }
    end
    attachment.merge!(
      title_link: test_run.url,
      fallback: attachment[:title],
      text: text)

    channel = project_channel if Houston::Slack.connection.channels.include? project_channel
    channel ||= nickname
    channel ||= "developers"

    slack_send_message_to nil, channel, attachments: [attachment]
  end
end
