class Account < ApplicationRecord
  pay_customer default_payment_processor: :stripe

  has_many :managers, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :crew_members, dependent: :destroy
  has_many :invites, dependent: :destroy

  validates :name, presence: true

  # Pay gem requires an email to create Stripe customers
  def email
    managers.order(:created_at).first&.email_address
  end
  validates :subdomain, uniqueness: true, allow_blank: true

  def active_subscription?
    return false unless payment_processor
    payment_processor.subscriptions.active.any?
  end

  def plan_name
    return "free" unless payment_processor
    payment_processor.subscriptions.active.order(created_at: :desc).first&.name || "free"
  end

  PROJECT_LIMITS = {
    "free" => 2,
    "starter" => 10,
    "pro" => nil  # unlimited
  }.freeze

  CREW_LIMITS = {
    "free" => 5,
    "starter" => 15,
    "pro" => nil  # unlimited
  }.freeze

  # Keep legacy constant for compatibility
  PLAN_LIMITS = PROJECT_LIMITS

  def project_limit
    PROJECT_LIMITS.fetch(plan_name, 2)
  end

  def project_limit_reached?
    project_limit && projects.count >= project_limit
  end

  def crew_member_limit
    CREW_LIMITS.fetch(plan_name, 5)
  end

  def crew_member_limit_reached?
    crew_member_limit && crew_members.count >= crew_member_limit
  end

  def project_usage_percent
    return 0 unless project_limit
    [ (projects.count * 100.0 / project_limit).round, 100 ].min
  end

  def crew_member_usage_percent
    return 0 unless crew_member_limit
    [ (crew_members.count * 100.0 / crew_member_limit).round, 100 ].min
  end
end
