require "application_system_test_case"

class AccountsSystemTest < ApplicationSystemTestCase
  test "sign-up, sign-in and reset pages are accessible, including with errors shown" do
    visit new_user_registration_path
    assert_selector "h1", text: "JOIN THE TRYBE"
    assert_accessible
    click_on "Continue"
    assert_selector ".error-summary"
    assert_accessible

    visit new_user_session_path
    assert_accessible
    visit new_user_password_path
    assert_accessible
  end

  test "a member signs in, picks a handle and manages their account" do
    user = User.new(email: "walk@example.com", password: "correct horse battery", birth_year: 2000, accept_terms: true, accept_sensitive_data: true)
    user.skip_confirmation!
    user.save!

    visit new_user_session_path
    fill_in "Email", with: "walk@example.com"
    fill_in "Password", with: "correct horse battery"
    click_on "Continue"

    assert_selector "h1", text: "PICK A HANDLE"
    assert_accessible
    fill_in "Handle", with: "walker"
    click_on "Continue"

    assert_selector "h1", text: "YOUR ACCOUNT"
    assert_text "@walker"
    assert_accessible
  end

  test "password visibility toggle exposes its state" do
    visit new_user_session_path
    toggle = find("button[aria-label='Show password']")
    assert_equal "false", toggle["aria-pressed"]
    toggle.click
    assert_equal "true", toggle["aria-pressed"]
    assert_equal "text", find("#user_password")["type"]
  end
end
