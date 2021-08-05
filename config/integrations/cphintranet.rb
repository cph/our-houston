$cphintranet = Faraday.new(url: "http://cphintranet")
$cphintranet.response :raise_error

