require "test_helper"
require "support/collecting_sender"


class ExceptionReportingTest < ActionDispatch::IntegrationTest
  attr_reader :project

  setup do
    Airbrake.sender = CollectingSender.new
    Airbrake.configuration.development_environments = []
    Airbrake.configuration.async = false
    @project = Project.create(name: "Test", slug: "test")
  end


  context "when an exception occurs during a normal web hook, it" do
    setup do
      # Suppose we're listening for this
      Houston.observer.on("hooks:project:something") { }
    end

    should "report the exception" do
      begin
        mock(Houston.observer).fire("hooks:project:something", anything) { raise "hell" }
        post "/projects/#{project.slug}/hooks/something"
      rescue
      end
      assert_equal 1, Airbrake.sender.collected.count,
        "Expected Houston to have reported this exception to Errbit"
    end
  end


  context "when an exception occurs during the exception_report webhook, it" do
    setup do
      # Suppose we're listening for this
      Houston.observer.on("hooks:project:exception_report") { }
    end

    should "not report the exception" do
      begin
        mock(Houston.observer).fire("hooks:project:exception_report", anything) { raise "hell" }
        post "/projects/#{project.slug}/hooks/exception_report"
      rescue
      end
      assert Airbrake.sender.collected.empty?,
        "Expected Houston not to send an exception report for an error " <<
        "that occurred when receiving an exception report (so as not to " <<
        "lock Houston and Errbit in an infinite loop)."
    end
  end

end
