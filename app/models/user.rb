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
class User < ApplicationRecord
  include Trestle::Auth::ModelMethods
  include Trestle::Auth::ModelMethods::Rememberable

  has_many :entries

  validates :alias_code, presence: true, uniqueness: true, length: { is: 3 }, format: { with: /\A[A-Z]+\z/, message: "must be 3 uppercase letters only" }

  scope :admins, -> { where(admin: true) }

  def admin?
    admin
  end

  before_save :uppercase_alias_code

  scope :ordered_by_creation_date, -> { order(created_at: :asc) }

  private

  def uppercase_alias_code
    self.alias_code = alias_code.upcase if alias_code.present?
  end
end