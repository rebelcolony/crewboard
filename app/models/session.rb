class Session < ApplicationRecord
  belongs_to :manager

  before_create { self.token = SecureRandom.urlsafe_base64(32) }
end
