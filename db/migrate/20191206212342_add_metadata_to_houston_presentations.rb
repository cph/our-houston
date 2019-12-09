class AddMetadataToHoustonPresentations < ActiveRecord::Migration[5.0]
  def change
    add_column :houston_presentations, :metadata, :jsonb, null: false, default: {}
  end
end
