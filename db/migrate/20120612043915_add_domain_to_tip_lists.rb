class AddDomainToTipLists < ActiveRecord::Migration
  def change
    add_column :tip_lists, :domain, :string
  end
end
