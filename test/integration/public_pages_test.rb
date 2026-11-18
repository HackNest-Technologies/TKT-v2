require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  STUB_PATHS = %w[/watch /community /support /give /blog /events /store /team /devotions
                  /share-testimony /privacy /terms].freeze

  test "landing page renders the design's main sections" do
    get root_path
    assert_response :success
    assert_select "h1", "Stream, Belong, Heal."
    assert_select "h2", text: "One platform. Three ways to grow."
    assert_select "h2", text: "Belong to a Trybe."
    assert_select "h2", text: "Support the mission."
    assert_select "a.skip-link[href='#main']"
    assert_select "nav[aria-label='Main'] a", minimum: 6
  end

  test "landing page does not advertise counselling features that are out of v1" do
    get root_path
    assert_no_match(/BetterHelp/i, response.body)
    assert_no_match(/Request Counselling/i, response.body)
    assert_no_match(/AI intake/i, response.body)
  end

  test "every placeholder page renders with its fixed title" do
    STUB_PATHS.each do |path|
      get path
      assert_response :success, "expected #{path} to render"
      assert_select "h1"
    end
  end

  test "unknown paths return 404" do
    get "/definitely-not-a-page"
    assert_response :not_found
  end

  test "health endpoint checks the database" do
    get health_check_path
    assert_response :success
    assert_equal "ok", response.body
  end

  test "health endpoint hides details when the database fails" do
    connection = ActiveRecord::Base.connection
    connection.define_singleton_method(:select_value) { |*| raise ActiveRecord::ConnectionNotEstablished, "secret detail" }
    begin
      get health_check_path
    ensure
      connection.singleton_class.send(:remove_method, :select_value)
    end
    assert_response :service_unavailable
    assert_equal "unavailable", response.body
  end
end
