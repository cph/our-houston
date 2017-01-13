class CreateHoustonPresentations < ActiveRecord::Migration
  def change
    create_table :houston_presentations do |t|
      t.string :title
      t.text :description
      t.date :date

      t.timestamps null: false
    end
  end
end
