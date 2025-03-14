class ChangePaidDefaultInEntries < ActiveRecord::Migration[6.0]
  def change
    change_column_default :entries, :paid, true
  end
end