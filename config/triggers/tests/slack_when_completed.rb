Houston.config do
  on "test_run:complete" do |test_run|
    # When branch is nil, the test run was requested by Houston
    # not triggered by a developer pushing changes to GitHub.
    next if test_run.branch.nil?
    next if test_run.aborted?

    branch = "#{test_run.project.slug}/#{test_run.branch}"
    text = test_run.short_description(with_duration: true) + "\n"
    attachment = case test_run.result
    when "pass"
      { color: "#5DB64C",
        title: "All tests passed on #{branch}" }
    when "fail"
      if test_run.fail_count > 0
        text << "```"
        test_run.failing_tests.each do |test|
          suite = test[:suite].gsub("__", "::")
          name = test[:name].to_s.gsub(/^(test :|: )/, "")
          text << "\n#{suite}: #{name}\n"
        end
        text << "```"
      end

      { color: "#E24E32",
        title: "#{test_run.fail_count} #{test_run.fail_count == 1 ? "test" : "tests"} failed on #{branch}" }
    else
      { color: "#DFCC3D",
        title: "The tests are broken on #{branch}" }
    end
    attachment.merge!(
      title_link: test_run.url,
      fallback: attachment[:title],
      text: text,
      mrkdwn_in: %w{text})

    channels = test_run.commit.committers.map(&:slack_username).reject(&:nil?)
    channels = %w{developers-only} if channels.empty?
    slack_send_message_to nil, channels, attachments: [attachment]
  end
end
