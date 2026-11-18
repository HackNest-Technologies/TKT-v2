require "application_system_test_case"

class LandingTest < ApplicationSystemTestCase
  test "landing page has no WCAG A/AA violations" do
    visit root_path
    assert_selector "h1", text: "STREAM, BELONG, HEAL."
    assert_accessible
  end

  test "keyboard users can skip to content" do
    visit root_path
    find("body").send_keys(:tab)
    assert_equal "Skip to content", page.evaluate_script("document.activeElement.textContent").strip
  end

  test "mobile menu opens, exposes state, and closes on Escape" do
    page.current_window.resize_to(402, 874)
    visit root_path
    toggle = find("button.nav-toggle")
    assert_equal "false", toggle["aria-expanded"]
    toggle.click
    assert_equal "true", toggle["aria-expanded"]
    assert_selector "#site-nav a", text: "WATCH"
    find("body").send_keys(:escape)
    assert_equal "false", toggle["aria-expanded"]
    assert_accessible
  end

  test "placeholder pages are accessible" do
    visit give_path
    assert_accessible
  end
end
