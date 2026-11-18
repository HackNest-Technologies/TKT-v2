require "test_helper"

class RateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.cache.store = @original_store
    Rack::Attack.enabled = false
  end

  test "sign-in attempts are throttled per IP after 10 a minute" do
    10.times { post "/users/sign_in", params: { user: { email: "a@example.com" } } }
    assert_not_equal 429, response.status
    post "/users/sign_in", params: { user: { email: "a@example.com" } }
    assert_response :too_many_requests
    assert_equal "60", response.headers["retry-after"]
  end

  test "sign-in attempts are throttled per account across IPs" do
    10.times do |i|
      post "/users/sign_in", params: { user: { email: "Victim@Example.com " } }, headers: { "CF-Connecting-IP" => "198.51.100.#{i}" }
    end
    post "/users/sign_in", params: { user: { email: "victim@example.com" } }, headers: { "CF-Connecting-IP" => "198.51.100.99" }
    assert_response :too_many_requests
  end
end
