class Manager < ApplicationRecord
  include Tenantable

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sent_invites, class_name: "Invite", foreign_key: :invited_by_id, dependent: :nullify

  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: 2.hours do
    password_salt&.last(10)
  end
end
