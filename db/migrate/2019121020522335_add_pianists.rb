class AddPianists < ActiveRecord::Migration[5.0]
  def change
    create_table :pianists do |t|
      t.integer :user_id, null: false

      t.integer :year, null: false
      t.integer :month, null: false

      t.timestamps

      t.index %i{year month}, unique: true
    end
  end
end
