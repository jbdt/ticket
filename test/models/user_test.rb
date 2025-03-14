# == Schema Information
#
# Table name: users
#
#  id                        :bigint           not null, primary key
#  admin                     :boolean          default(FALSE), not null
#  alias_code                :string
#  email                     :string
#  password_digest           :string
#  remember_token            :string
#  remember_token_expires_at :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
