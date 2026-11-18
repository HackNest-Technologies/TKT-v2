require "test_helper"

class GoogleSignInTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  def mock_google(uid: "g-123", email: "gamer@example.com", verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: uid, info: { email: email },
      extra: { raw_info: { email_verified: verified } }
    )
  end

  def google_callback
    get user_google_oauth2_omniauth_callback_path
  end

  test "a new Google member is created confirmed and must complete age, consents and handle" do
    mock_google
    assert_difference -> { User.count } => 1, -> { Identity.count } => 1 do
      google_callback
    end
    user = User.find_by!(email: "gamer@example.com")
    assert user.confirmed?
    assert_redirected_to profile_setup_path

    patch profile_setup_path, params: { user: { handle: "gamer_one" } }
    assert_response :unprocessable_entity # age + consents still missing

    patch profile_setup_path, params: { user: { handle: "gamer_one", birth_year: 2003, confirm_minimum_age: "1", accept_terms: "1", accept_sensitive_data: "1" } }
    assert_redirected_to account_path
    assert_equal 2, user.reload.consents.count
  end

  test "a Google member under 16 has the account closed" do
    mock_google
    google_callback
    patch profile_setup_path, params: { user: { handle: "kid_gamer", birth_year: Date.current.year - 14, confirm_minimum_age: "1", accept_terms: "1", accept_sensitive_data: "1" } }
    assert_redirected_to root_path
    assert User.find_by(email: "gamer@example.com").deletion_requested_at
  end

  test "an unverified Google email is refused" do
    mock_google(verified: false)
    assert_no_difference -> { User.count } do
      google_callback
    end
    assert_redirected_to new_user_session_path
  end

  test "a verified Google email links to the existing account instead of duplicating it" do
    existing = create_user(email: "gamer@example.com")
    mock_google
    assert_no_difference -> { User.count } do
      google_callback
    end
    assert_equal existing, Identity.last.user
  end

  test "Google sign-in start only accepts POST (CSRF-protected)" do
    get user_google_oauth2_omniauth_authorize_path
    assert_includes [ 404, 405 ], response.status
  end
end
