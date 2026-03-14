class Invite < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "Manager"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_not_already_on_account, on: :create
  validate :no_pending_invite, on: :create

  normalizes :email, with: ->(e) { e.strip.downcase }

  before_create { self.token = SecureRandom.urlsafe_base64(32) }

  scope :pending, -> { where(accepted_at: nil).where("created_at > ?", 7.days.ago) }

  def expired?
    created_at < 7.days.ago
  end

  def accepted?
    accepted_at.present?
  end

  def pending?
    !accepted? && !expired?
  end

  private

  def email_not_already_on_account
    if account&.managers&.exists?(email_address: email)
      errors.add(:email, "is already a member of this account")
    end
  end

  def no_pending_invite
    if account&.invites&.pending&.exists?(email: email)
      errors.add(:email, "already has a pending invite")
    end
  end
end
