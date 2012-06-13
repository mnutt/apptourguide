class AddYOffsetToTips < ActiveRecord::Migration
  def change
    add_column :tips, :y_offset, :integer
  end
end
