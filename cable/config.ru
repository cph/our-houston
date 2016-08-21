$WEB_SERVER = :action_cable

# Load and configure Houston
require_relative "../config/main"

Rails.application.eager_load!

require "action_cable/process/logging"
run ActionCable.server
