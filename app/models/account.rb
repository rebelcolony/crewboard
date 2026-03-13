class Account < ApplicationRecord
  pay_customer default_payment_processor: :stripe

  has_many :managers, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :crew_members, dependent: :destroy

  validates :name, presence: true

  # Pay gem requires an email to create Stripe customers
  def email
    managers.order(:created_at).first&.email_address
  end
  validates :subdomain, uniqueness: true, allow_blank: true

  def active_subscription?
    payment_processor&.subscription&.active? || false
  end

  def plan_name
    payment_processor&.subscription&.name || "free"
  end
end
