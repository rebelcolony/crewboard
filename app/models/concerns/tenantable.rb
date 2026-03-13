module Tenantable
  extend ActiveSupport::Concern

  included do
    belongs_to :account
    scope :for_current_account, -> { where(account: Current.account) }
  end
end
