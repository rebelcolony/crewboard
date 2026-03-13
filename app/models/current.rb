class Current < ActiveSupport::CurrentAttributes
  attribute :session, :account

  delegate :manager, to: :session, allow_nil: true
end
