module UserExt

  module ClassMethods
    def find_ldap_entry(ldap_connection, auth_key_value)
      filter = Net::LDAP::Filter.eq("samaccountname", auth_key_value)
      ldap_connection.ldap.search(filter: filter).first
    end

    def find_for_ldap_authentication(attributes, entry)
      email = entry.mail.first.downcase
      user = where(email: email).first
      if user && user.username.nil?
        user.update_column :username, entry["samaccountname"][0].to_s
      end
      user
    end

    def create_from_ldap_entry(attributes, entry)
      create!(
        email: entry.mail.first.downcase,
        username: entry["samaccountname"][0].to_s,
        password: attributes[:password],
        first_name: entry.givenname.first,
        last_name: entry.sn.first )
    end
  end

end
