Houston.config.authentication_strategy :ldap do
  instructions "You can log in with your CPH domain account"
  if Rails.env.development?
    host "10.5.3.100"
    port 636
    ssl :simple_tls
  else
    host "172.31.1.253"
    port 389
  end
  base "dc=cph, dc=pri"
  field "samaccountname"
  username_builder Proc.new { |attribute, login, ldap| "#{login}@cph.pri" }
end
