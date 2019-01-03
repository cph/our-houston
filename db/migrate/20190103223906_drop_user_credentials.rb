class DropUserCredentials < ActiveRecord::Migration[5.0]
  def up
    drop_table :user_credentials
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
