class PopulateErrorType < ActiveRecord::Migration[5.0]
  def up
    Error.where(message: "Net::OpenTimeout").update_all(type: "Net::OpenTimeout")
    Error.where(message: "Net::ReadTimeout").update_all(type: "Net::ReadTimeout")
    Error.where(message: "execution expired").update_all(type: "Net::OpenTimeout")
    Error.where(message: "getaddrinfo: Name or service not known").update_all(type: "Faraday::ConnectionFailed")
    Error.where(message: "Couldn't find a private group named ops").update_all(type: "ArgumentError")
    Error.where(message: "wrong number of arguments (3 for 1..2)").update_all(type: "ArgumentError")
    Error.where(message: "SSL_connect SYSCALL returned=5 errno=0 state=SSLv3 read server session ticket A").update_all(type: "Faraday::SSLError")
    Error.where(message: "uninitialized constant Job").update_all(type: "NameError")
    Error.where(message: "Unable to connect: Adaptive Server is unavailable or does not exist").update_all(type: "TinyTds::Error")
    Error.where(message: "Connection timed out - connect(2) for \"api.gemnasium.com\" port 443").update_all(type: "Faraday::TimeoutError")
    Error.where(message: "401 from starweb/WebService.asmx/GetUserTimeForDay").update_all(type: "Faraday::HTTP::Unauthorized")
    Error.where(["message like ?", "undefined method `%"]).update_all(type: "NoMethodError")
    Error.where(["message like ?", "undefined local variable or method `%"]).update_all(type: "NameError")
    Error.where(["message like ?", "SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify%"]).update_all(type: "Faraday::SSLError")
    Error.where(["message like ?", "could not obtain a%"]).update_all(type: "ActiveRecord::ConnectionTimeoutError")
    Error.where(["message like ?", "Unable to serialize a Sawyer::Resource%"]).update_all(type: "Houston::Serializer::UnserializableError")
    Error.where(["message like ?", "Project#maintainers delegated to team.maintainers%"]).update_all(type: "Module::DelegationError")
  end
end
