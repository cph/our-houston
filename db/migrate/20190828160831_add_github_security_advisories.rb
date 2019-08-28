class AddGithubSecurityAdvisories < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE SEQUENCE github_security_advisories_seq;
    SQL

    create_table :github_security_advisories do |t|
      t.string :ghsa_id
      t.integer :number, null: false, default: -> { "7000000 + nextval('github_security_advisories_seq')" }

      t.index :ghsa_id, unique: true
      t.index :number
    end

    execute <<~SQL
      ALTER SEQUENCE github_security_advisories_seq
        OWNED BY github_security_advisories.number;
    SQL
  end

  def down
    drop_table :github_security_advisories
  end
end
