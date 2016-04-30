logeater_database_url = ENV["LOGEATER_DATABASE_URL"]
if logeater_database_url
  uri = Addressable::URI.parse(logeater_database_url)
  config = {
    adapter: "postgresql",
    encoding: "utf8",
    min_messages: "WARNING",
    database: uri.path[1..-1],
    host: uri.host,
    username: uri.user,
    password: uri.password,
    port: uri.port
  }
  Logeater::Request.establish_connection config
end
