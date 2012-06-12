class CreateTips < ActiveRecord::Migration
  def change
    create_table :tips do |t|
      t.string :description
      t.integer :num
      t.string :direction
      t.integer :x_offset
      t.integer :x_offset
      t.string :parent
      t.integer :tip_list_id

      t.timestamps
    end
  end
end
