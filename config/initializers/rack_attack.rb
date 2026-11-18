# Rate limits and abuse controls. Counters live in Rails.cache (Solid Cache in production).
class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  # Client IP as seen through Cloudflare (CF-Connecting-IP), falling back to the socket.
  def self.client_ip(req)
    req.get_header("HTTP_CF_CONNECTING_IP").presence || req.ip
  end

  # General ceiling: 300 requests per 5 minutes per IP (assets and health checks excluded).
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    client_ip(req) unless req.path.start_with?("/assets", "/up", "/health")
  end

  # Sign-in: 10 per minute per IP, 10 per 15 minutes per account.
  throttle("signin/ip", limit: 10, period: 1.minute) do |req|
    client_ip(req) if req.post? && req.path == "/users/sign_in"
  end
  throttle("signin/email", limit: 10, period: 15.minutes) do |req|
    if req.post? && req.path == "/users/sign_in"
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  # Sign-up, password reset, confirmation resend: 5 per 15 minutes per IP.
  throttle("account-mail/ip", limit: 5, period: 15.minutes) do |req|
    client_ip(req) if req.post? && %w[/users /users/password /users/confirmation].include?(req.path)
  end

  # Writes (reactions, votes, comments): 60 per minute per IP.
  throttle("writes/ip", limit: 60, period: 1.minute) do |req|
    client_ip(req) if (req.post? || req.patch? || req.put? || req.delete?) && !req.path.start_with?("/users")
  end

  self.throttled_responder = lambda do |_req|
    [ 429, { "content-type" => "text/plain", "retry-after" => "60" }, [ "Too many requests. Please wait a minute and try again.\n" ] ]
  end
end
