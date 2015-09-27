ENV["RAILS_ENV"] ||= "test"

# Load and configure Houston
require_relative "../config/main"

# Initialize the Rails application
Rails.application.initialize!

require "rails/test_help"
require "minitest/reporters"
require "minitest/reporters/turn_reporter"
MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new
