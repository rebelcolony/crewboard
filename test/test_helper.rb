ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

# Sign-in helper for request (controller/integration) tests
module SignInHelper
  def sign_in(manager)
    session = manager.sessions.first || manager.sessions.create!(
      ip_address: "127.0.0.1",
      user_agent: "Test"
    )
    cookies.signed[:session_token] = session.token
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
