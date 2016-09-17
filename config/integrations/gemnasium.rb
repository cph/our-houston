# Configuration for Gemnasium
$gemnasium = Faraday.new(url: "https://api.gemnasium.com/v1/")
$gemnasium.basic_auth "X", ENV["HOUSTON_GEMNASIUM_API_KEY"]
$gemnasium.use Faraday::RaiseErrors
