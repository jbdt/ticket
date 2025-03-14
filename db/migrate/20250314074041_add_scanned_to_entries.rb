class AddScannedToEntries < ActiveRecord::Migration[6.1]
  def change
    add_column :entries, :scanned, :json, default: []
  end
end
