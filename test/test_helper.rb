ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

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
    post session_path, params: { email_address: manager.email_address, password: "password123" }
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
