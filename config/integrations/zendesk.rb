ZENDESK_HOST = (Rails.env.production? ? "concordiatech.zendesk.com" : "concordiatech1446588092.zendesk.com").freeze
ZENDESK_TOKEN = (Rails.env.production? ? ENV["HOUSTON_ZENDESK_TOKEN"] : ENV["HOUSTON_DEV_ZENDESK_TOKEN"]).freeze

$zendesk = Faraday.new(url: "https://#{ZENDESK_HOST}/api/v2")
$zendesk.basic_auth "houston@cphepdev.com/token", ZENDESK_TOKEN
$zendesk.response :raise_error
