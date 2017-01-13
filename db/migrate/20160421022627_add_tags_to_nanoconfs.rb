class AddTagsToNanoconfs < ActiveRecord::Migration
  def change
    add_column :nanoconf_presentations, :tags, :text, array: true
  end
end
