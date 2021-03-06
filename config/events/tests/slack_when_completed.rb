Houston.config do
  on "test_run:complete" => "test_run:slack-results" do
    # When branch is nil, the test run was requested by Houston
    # not triggered by a developer pushing changes to GitHub.
    next if test_run.branch.nil?
    next if test_run.aborted?

    text = test_run.short_description(with_duration: true) + "\n"
    attachment = case test_run.result
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

      { color: "#E24E32" }
    when "pass"
      { color: "#5DB64C" }
    else
      { color: "#DFCC3D" }
    end
    attachment.merge!(
      title: test_run.summary,
      title_link: test_run.url,
      fallback: test_run.summary,
      text: text,
      mrkdwn_in: %w{text})

    channels = test_run.commit.committers.map(&:slack_username).reject(&:nil?)
    channels = %w{ep-developers} if channels.empty?
    slack_send_message_to nil, channels, attachments: [attachment]
  end
end
