# == Schema Information
#
# Table name: entries
#
#  id                 :bigint           not null, primary key
#  code               :string           not null
#  comments           :text
#  email              :string
#  entry_type         :string           not null
#  name               :string
#  phone              :string
#  status             :string           default("created"), not null
#  ticket_number      :integer
#  user_ticket_number :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_entries_on_code     (code) UNIQUE
#  index_entries_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class EntryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
