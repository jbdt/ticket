class AddPaidToEntries < ActiveRecord::Migration[6.1]
  def change
    add_column :entries, :paid, :boolean
  end
end
