class CrewMember < ApplicationRecord
  include Tenantable

  belongs_to :project, optional: true
  validates :name, presence: true

  enum :status, { available: "available", on_leave: "on_leave" }, default: "available"

  def initials
    name.split.map(&:first).join.upcase[0, 2]
  end

  def avatar_url(size: 80)
    # Disabled for demo — initials only
    # hash = Digest::MD5.hexdigest(email.to_s.downcase)
    # "https://i.pravatar.cc/#{size}?u=#{hash}"
    nil
  end

  def assigned?
    project_id.present?
  end
end
