require "user_ext"

module Houston
  class Railtie < ::Rails::Railtie

    # The block you pass to this method will run for every request
    # in development mode, but only once in production.
    config.to_prepare do
      ::User.devise :ldap_authenticatable
      User.extend UserExt::ClassMethods
    end

  end
end
