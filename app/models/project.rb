class Project < ApplicationRecord
  include Tenantable

  has_many :crew_members, dependent: :nullify

  enum :status, { not_started: 0, in_progress: 1, on_hold: 2, completed: 3 }

  validates :name, presence: true
  validates :progress, numericality: { in: 0..100 }, allow_nil: true

  def progress
    super || 0
  end

  def status_color
    case status
    when "completed" then "success"
    when "in_progress" then "accent"
    when "on_hold" then "warning"
    else "secondary"
    end
  end
end
