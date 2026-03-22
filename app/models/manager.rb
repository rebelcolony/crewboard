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

  # Email verification
  scope :unverified, -> { where(email_verified_at: nil) }
  scope :verified, -> { where.not(email_verified_at: nil) }

  def generate_email_verification_token!
    update!(
      email_verification_token: SecureRandom.hex(32),
      email_verification_token_generated_at: Time.current
    )
  end

  def email_verified?
    email_verified_at.present?
  end

  def verify_email_with_token!(token)
    return false if token.blank?
    return false if email_verified?

    # Check if token exists and is not expired (24 hours)
    if email_verification_token == token && email_verification_token_generated_at&.after?(24.hours.ago)
      update!(
        email_verified_at: Time.current,
        email_verification_token: nil,
        email_verification_token_generated_at: nil
      )
      return true
    end

    false
  end

  def email_verification_token_expired?
    email_verification_token.present? &&
      email_verification_token_generated_at&.before?(24.hours.ago)
  end
end
