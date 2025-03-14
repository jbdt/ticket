class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :alias_code
      t.string :email
      t.string :password_digest
      t.boolean :admin, default: false, null: false
      t.string :remember_token
      t.datetime :remember_token_expires_at

      t.timestamps
    end
  end
end
