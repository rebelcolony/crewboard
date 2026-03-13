class Manager < ApplicationRecord
  include Tenantable

  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true
  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
