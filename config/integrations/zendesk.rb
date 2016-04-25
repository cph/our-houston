ZENDESK_HOST = (Rails.env.production? ? "https://concordiatech.zendesk.com" : "https://concordiatech1446588092.zendesk.com").freeze

$zendesk = ZendeskAPI::Client.new do |config|
  config.url = "#{ZENDESK_HOST}/api/v2"
  config.username = "houston@cphepdev.com"

  if Rails.env.production?
    config.token = ENV["HOUSTON_ZENDESK_TOKEN"]
  else
    config.token = ENV["HOUSTON_DEV_ZENDESK_TOKEN"]
  end

  # Retry uses middleware to notify the user
  # when hitting the rate limit, sleep automatically,
  # then retry the request.
  config.retry = true

  # Logger prints to STDERR by default, to e.g. print to stdout:
  # require "logger"
  # config.logger = Logger.new(STDOUT)

  # Changes Faraday adapter
  # config.adapter = :patron

  # Merged with the default client options hash
  # config.client_options = { :ssl => false }

  # When getting the error 'hostname does not match the server certificate'
  # use the API at https://yoursubdomain.zendesk.com/api/v2
end

ZENDESK_BRAND_PROJECT_MAP = {
  "360ledger" => "ledger",
  "360members" => "members",
  "360unite" => "unite",
  "biblestudybuilder" => "bsb",
  "bible101" => "bible101",
  "confirmationbuilder" => "confb",
  "lsb" => "lsb",
  "mysundaysolutions" => "musicmate",
  "oic" => "oic",
  "shepherdsstaff" => "shepherdsstaff" }.freeze

ZENDESK_BRANDS = $zendesk.brands.each_with_object({}) { |brand, map|
  map[brand.id] = ZENDESK_BRAND_PROJECT_MAP.fetch(brand.subdomain, brand.subdomain) }.freeze
