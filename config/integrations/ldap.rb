Houston.config.authentication_strategy :ldap do
  instructions "You can log in with your CPH domain account"
  host "172.31.1.253"
  port 389
  base "dc=cph, dc=pri"
  field "samaccountname"
  username_builder Proc.new { |attribute, login, ldap| "#{login}@cph.pri" }
end
