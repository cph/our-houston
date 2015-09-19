Houston.config.authentication_strategy :ldap do
  # host "10.5.3.100"
  # port 636
  # ssl :simple_tls
  host "172.31.1.253"
  port 389
  base "dc=cph, dc=pri"
  username_builder Proc.new { |attribute, login, ldap| "#{login}@cph.pri" }
end
