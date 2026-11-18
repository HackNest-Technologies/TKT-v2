require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  setup { get root_path }

  test "content security policy is strict" do
    csp = response.headers["Content-Security-Policy"]
    assert_match(/default-src 'self'/, csp)
    assert_match(/object-src 'none'/, csp)
    assert_match(/frame-ancestors 'none'/, csp)
    assert_match(/script-src 'self' 'nonce-/, csp)
    assert_no_match(/unsafe-inline|unsafe-eval/, csp)
  end

  test "pages contain no inline style attributes or inline event handlers (would be blocked by CSP)" do
    assert_no_match(/\sstyle="/, response.body)
    assert_no_match(/\son[a-z]+="/i, response.body)
  end

  test "hardening headers are present" do
    assert_equal "DENY", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
    assert_equal "same-origin", response.headers["Cross-Origin-Opener-Policy"]
    assert_match(/camera=\(\)/, response.headers["Permissions-Policy"])
  end

  test "session cookie is HttpOnly and SameSite=Lax" do
    reset! # fresh client: the session cookie is only sent when first created
    sign_in_as(create_user)
    cookie = Array(response.headers["Set-Cookie"]).join("\n")
    assert_match(/_tkt_session=/, cookie)
    assert_match(/httponly/i, cookie)
    assert_match(/samesite=lax/i, cookie)
  end
end
