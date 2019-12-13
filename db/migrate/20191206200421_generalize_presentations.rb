class GeneralizePresentations < ActiveRecord::Migration[5.0]
  def up
    rename_table :nanoconf_presentations, :houston_presentations
    add_column :houston_presentations, :type, :string
    execute <<~SQL
      UPDATE houston_presentations SET type='Presentation::Nanoconf'
    SQL
    change_column_null :houston_presentations, :type, false
  end

  def down
    remove_column :houston_presentations, :type
    rename_table :houston_presentations, :nanoconf_presentations
  end
end
