require "test_helper"

class AccountsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  def sign_up(**overrides)
    params = { email: "new@example.com", password: "a long passphrase", birth_year: 2001,
               confirm_minimum_age: "1", accept_terms: "1", accept_sensitive_data: "1" }.merge(overrides)
    post user_registration_path, params: { user: params }
  end

  # --- Sign-up ---------------------------------------------------------------

  test "sign-up creates an unconfirmed account, records consents and sends a confirmation email" do
    perform_enqueued_jobs do
      assert_difference -> { User.count } => 1, -> { Consent.count } => 2 do
        sign_up
      end
    end
    user = User.find_by!(email: "new@example.com")
    assert_not user.confirmed?
    assert user.terms_accepted_at && user.sensitive_data_consent_at
    assert_equal %w[sensitive_data_processing terms_and_privacy], user.consents.pluck(:purpose).sort
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_redirected_to new_user_session_path
  end

  test "unconfirmed accounts cannot sign in" do
    sign_up
    sign_in_as(User.last, password: "a long passphrase")
    assert_redirected_to new_user_session_path
    assert_match "confirm your email", flash[:alert]
    get account_path
    assert_redirected_to new_user_session_path
  end

  test "under-16 sign-ups are refused and nothing is stored" do
    assert_no_difference -> { User.count } do
      sign_up(birth_year: Date.current.year - 15)
    end
    assert_response :unprocessable_entity
    assert_match "aged 16 and over", response.body
  end

  test "sign-up requires age confirmation and both consents" do
    assert_no_difference -> { User.count } do
      sign_up(confirm_minimum_age: "0", accept_terms: "0", accept_sensitive_data: "0")
    end
    assert_response :unprocessable_entity
    assert_select ".error-summary li", minimum: 3
    assert_select "input[aria-invalid='true']", minimum: 3
  end

  test "passwords shorter than 12 characters are rejected" do
    assert_no_difference -> { User.count } do
      sign_up(password: "short")
    end
    assert_select ".field__error", /too short/
  end

  # --- Handle step -------------------------------------------------------------

  test "a new member is sent to pick a handle, which must be valid and unique" do
    create_user(handle: "taken_name")
    user = create_user(handle: nil)
    sign_in_as(user)
    assert_redirected_to profile_setup_path

    get account_path
    assert_redirected_to profile_setup_path

    %w[taken_name TAKEN_NAME admin no spaces! a].each do |bad|
      patch profile_setup_path, params: { user: { handle: bad } }
      assert_response :unprocessable_entity, "expected #{bad.inspect} to be rejected"
    end

    patch profile_setup_path, params: { user: { handle: "@Good_Name" } }
    assert_redirected_to account_path
    assert_equal "Good_Name", user.reload.handle
  end

  # --- Sign-in protection -----------------------------------------------------

  test "accounts lock after 10 wrong passwords" do
    user = create_user
    10.times { sign_in_as(user, password: "wrong password!!") }
    assert user.reload.access_locked?
    sign_in_as(user)
    get account_path
    assert_redirected_to new_user_session_path
  end

  test "sign-in failures do not reveal whether the email exists" do
    create_user(email: "real@example.com")
    post user_session_path, params: { user: { email: "real@example.com", password: "wrong password!!" } }
    real = response.body[/<div class="flash[^>]*>([^<]+)</, 1]
    post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong password!!" } }
    fake = response.body[/<div class="flash[^>]*>([^<]+)</, 1]
    assert_equal real, fake
  end

  test "password reset requests give the same answer for unknown emails" do
    create_user(email: "real@example.com")
    post user_password_path, params: { user: { email: "real@example.com" } }
    real = flash[:notice]
    post user_password_path, params: { user: { email: "nobody@example.com" } }
    assert_equal real, flash[:notice]
  end

  # --- Sessions -----------------------------------------------------------------

  test "a session can be listed and revoked from another device; the revoked device is signed out" do
    user = create_user
    phone = open_session
    phone.post user_session_path, params: { user: { email: user.email, password: "correct horse battery" } }
    phone.get account_path
    assert_equal 200, phone.response.status

    sign_in_as(user)
    get account_path
    assert_select ".session-list__item", 2
    phone_session = user.user_sessions.active.order(:created_at).first
    delete device_session_path(phone_session)
    assert_redirected_to account_path

    phone.get account_path
    assert_equal 302, phone.response.status
    assert_equal new_user_session_url, phone.response.location
  end

  test "sign out everywhere else keeps this browser signed in" do
    user = create_user
    others = 2.times.map do
      s = open_session
      s.post user_session_path, params: { user: { email: user.email, password: "correct horse battery" } }
      s
    end
    sign_in_as(user)
    delete others_device_sessions_path
    assert_equal 1, user.user_sessions.active.count
    get account_path
    assert_response :success
    others.each do |s|
      s.get account_path
      assert_equal 302, s.response.status
    end
  end

  test "members cannot revoke another member's session (404, not 403)" do
    victim = create_user
    victim_session = open_session
    victim_session.post user_session_path, params: { user: { email: victim.email, password: "correct horse battery" } }

    sign_in_as(create_user)
    delete device_session_path(victim.user_sessions.active.first)
    assert_response :not_found
    assert victim.user_sessions.active.exists?
  end

  test "changing password signs out other devices but keeps this one" do
    user = create_user
    other = open_session
    other.post user_session_path, params: { user: { email: user.email, password: "correct horse battery" } }

    sign_in_as(user)
    put user_registration_path, params: { user: { password: "a brand new passphrase", password_confirmation: "a brand new passphrase", current_password: "correct horse battery" } }
    assert_redirected_to account_path
    get account_path
    assert_response :success
    other.get account_path
    assert_equal 302, other.response.status
  end

  test "signing out revokes the server-side session" do
    user = create_user
    sign_in_as(user)
    assert_equal 1, user.user_sessions.active.count
    delete destroy_user_session_path
    assert_equal 0, user.user_sessions.active.count
  end

  # --- Data rights ----------------------------------------------------------------

  test "data export contains the member's data and no secrets" do
    user = create_user
    sign_in_as(user)
    get export_account_path
    assert_response :success
    assert_equal "application/json", response.media_type
    data = JSON.parse(response.body)
    assert_equal user.email, data.dig("account", "email")
    assert_equal 2, data["consents"].size
    %w[encrypted_password reset_password_token token_digest ip_hash confirmation_token].each do |secret|
      assert_not_includes response.body, secret
    end
  end

  test "account deletion needs the password, locks the account, and is purged after 30 days" do
    user = create_user
    sign_in_as(user)
    delete account_path, params: { current_password: "wrong password!!" }
    assert_nil user.reload.deletion_requested_at

    delete account_path, params: { current_password: "correct horse battery" }
    assert_redirected_to root_path
    assert user.reload.deletion_requested_at
    assert_equal 0, user.user_sessions.active.count

    sign_in_as(user)
    get account_path
    assert_redirected_to new_user_session_path

    travel 31.days do
      AccountPurgeJob.perform_now
    end
    assert_not User.exists?(user.id)
    assert_equal 0, Consent.where(user_id: user.id).count
  end

  # --- Preview gate -----------------------------------------------------------------

  test "preview password protects every page except health checks" do
    ENV["PREVIEW_PASSWORD"] = "letmein-preview"
    get root_path
    assert_response :unauthorized
    get root_path, headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("tkt", "letmein-preview") }
    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    get "/up"
    assert_response :success
  ensure
    ENV.delete("PREVIEW_PASSWORD")
  end
end
