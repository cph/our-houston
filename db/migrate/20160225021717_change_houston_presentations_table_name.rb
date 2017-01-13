class ChangeHoustonPresentationsTableName < ActiveRecord::Migration
  def change
    rename_table :houston_presentations, :nanoconf_presentations
    add_column :nanoconf_presentations, :presenter_id, :integer
  end
end
