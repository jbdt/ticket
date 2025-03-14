class AddRedeemedToEntries < ActiveRecord::Migration[6.1]
  def change
    add_column :entries, :redeemed, :boolean
  end
end
