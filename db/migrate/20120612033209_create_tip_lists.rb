class CreateTipLists < ActiveRecord::Migration
  def change
    create_table :tip_lists do |t|
      t.string :name

      t.timestamps
    end
  end
end
