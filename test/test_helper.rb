ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def create_user(email: "member#{SecureRandom.hex(4)}@example.com", password: "correct horse battery", handle: "member_#{SecureRandom.hex(3)}", confirmed: true, **attrs)
      user = User.new(email: email, password: password, handle: handle, birth_year: 2000,
                      accept_terms: true, accept_sensitive_data: true, **attrs)
      user.skip_confirmation! if confirmed
      user.save!
      user
    end
  end
end

# Rate limiting is exercised only in RateLimitTest, so other tests can repeat requests freely.
Rack::Attack.enabled = false

module SignInHelper
  def sign_in_as(user, password: "correct horse battery")
    post user_session_path, params: { user: { email: user.email, password: password } }
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
