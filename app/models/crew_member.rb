class CrewMember < ApplicationRecord
  include Tenantable

  belongs_to :project, optional: true
  validates :name, presence: true

  def initials
    name.split.map(&:first).join.upcase[0, 2]
  end

  def avatar_url(size: 80)
    "https://i.pravatar.cc/#{size}?u=#{Digest::MD5.hexdigest(email.to_s.downcase)}"
  end

  def assigned?
    project_id.present?
  end
end
