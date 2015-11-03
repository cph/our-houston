MAX_BROKEN_TESTS = 5.freeze

Houston.config do
  on "test_run:compared" do |test_run|
    regressions = test_run.test_results.where(different: true, status: "fail").to_a
    next if regressions.none?

    commit = slack_link_to(test_run.sha[0...7], test_run.commit.url)
    predicate = "this test:" if regressions.count == 1
    predicate = "these tests:" if regressions.count > 1 && regressions.count <= MAX_BROKEN_TESTS
    predicate = "#{regressions.count} tests :cold_sweat:" if regressions.count > MAX_BROKEN_TESTS

    message = "Hey... I think this commit :point_right: *#{commit}* #{slack_link_to("broke", test_run.url)} #{predicate}"

    regressions.each do |regression|
      test = regression.test
      test_name = "*#{test.suite}* #{test.name}"
      url = "http://#{Houston.config.host}/projects/#{test.project.slug}/tests/#{test.id}?at=#{test_run.sha}"
      message << "\n> #{slack_link_to(test_name, url)}"
    end if regressions.count <= MAX_BROKEN_TESTS

    project_channel = "##{test_run.project.slug}"
    channels = [project_channel] if Houston::Slack.connection.channels.include? project_channel
    channels ||= test_run.commit.committers.map(&:slack_username).reject(&:nil?)
    channels = %w{developers-only} if Array(channel).empty?

    channels.each do |channel|
      slack_send_message_to message, channel
    end
  end
end
