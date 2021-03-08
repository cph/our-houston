$freshservice = Faraday.new(url: "https://cph.freshservice.com")
$freshservice.basic_auth ENV["HOUSTON_FRESHSERVICE_API_KEY"], "X"
$freshservice.response :raise_error
