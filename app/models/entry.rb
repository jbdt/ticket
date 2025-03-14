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
#  paid               :boolean          default(TRUE)
#  phone              :string
#  redeemed           :boolean
#  scanned            :json
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
class Entry < ApplicationRecord
  belongs_to :user

  enum status: { created: "created", sold: "sold", confirmed: "confirmed", redeemed: "redeemed", canceled: "canceled" }
  enum entry_type: { general: "general", vip: "vip", nomad: "nomad", premium: "premium", furama: "furama" }

  validates :code, presence: true, uniqueness: true
  validates :entry_type, presence: true
  validates :ticket_number, uniqueness: true
  validates :user_ticket_number, uniqueness: { scope: :user_id }

  # before_validation :assign_ticket_numbers, :generate_code
  before_save :update_status_to_sold_if_needed
  before_save :set_redeemed

  after_create :generate_ticket, if: :created?

  scope :ordered_by_creation_date, -> { order(created_at: :asc) }

  serialize :scanned, Array

  def qr_code
    RQRCode::QRCode.new(code)
  end

  def generate_ticket
    GenerateTicketJob.perform_later(id)
  end

  def add_scan
    update(scanned: scanned.push(Time.current.iso8601))
  end

  private

  def assign_ticket_numbers
    self.ticket_number ||= (Entry.maximum(:ticket_number) || 0) + 1
    self.user_ticket_number ||= (user.entries.maximum(:user_ticket_number) || 0) + 1
  end

  def generate_code
    assign_ticket_numbers if ticket_number.blank? || user_ticket_number.blank?

    formatted_ticket_number = user_ticket_number.to_s.rjust(4, '0')
    formatted_user_ticket_number = ticket_number.to_s.rjust(4, '0')

    control_digit = text_to_control_digit("#{formatted_user_ticket_number}-#{entry_type[0..2].upcase}--#{user.alias_code.upcase}-#{formatted_ticket_number}")

    self.code = "#{formatted_user_ticket_number}-#{entry_type[0..2].upcase}-#{control_digit}-#{user.alias_code.upcase}-#{formatted_ticket_number}"
  end

  def text_to_control_digit(text)
    hash_value = text.hash
    positive_hash = hash_value.abs
    control_digit = positive_hash % 100
    control_digit
  end

  def update_status_to_sold_if_needed
    if status == "created" && name.present? && phone.present? && email.present?
      self.status = "sold"
    end
  end

  def set_redeemed
    self.redeemed = scanned.present? && scanned.any?
  end
end
