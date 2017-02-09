require "devise_ldap_authenticatable"

# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  if Rails.env.development?
    config.ldap_configuration = {
      "host" => "10.5.3.100",
      "port" => 636,
      "ssl" => :simple_tls,
      "base" => "dc=cph, dc=pri",
      "field" => "samaccountname" }
  else
    config.ldap_configuration = {
      "host" => "172.31.1.253",
      "port" => 389,
      "base" => "dc=cph, dc=pri",
      "field" => "samaccountname" }
  end

  config.ldap_logger = true
  config.ldap_create_user = true
  config.ldap_update_password = false
  config.ldap_check_group_membership = false
  config.ldap_use_admin_to_bind = false
  config.ldap_ad_group_check = false
  config.ldap_auth_username_builder = Proc.new { |attribute, login, ldap| "#{login}@cph.pri" }
end
