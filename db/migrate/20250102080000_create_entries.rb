class CreateEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :entries do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.integer :ticket_number, unique: true
      t.integer :user_ticket_number
      t.string :code, null: false, unique: true
      t.string :entry_type, null: false
      t.references :user, null: false, foreign_key: true
      t.text :comments
      t.string :status, null: false, default: "created"

      t.timestamps
    end

    add_index :entries, :code, unique: true
  end
end
