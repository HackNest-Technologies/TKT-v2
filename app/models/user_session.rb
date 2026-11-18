# One row per signed-in browser. The cookie session holds a random token; only its
# SHA-256 digest is stored, so a database leak does not expose usable session tokens.
class UserSession < ApplicationRecord
  TOUCH_INTERVAL = 5.minutes

  belongs_to :user
  scope :active, -> { where(revoked_at: nil) }

  def self.start!(user, request)
    token = SecureRandom.urlsafe_base64(32)
    create!(user: user, token_digest: digest(token), user_agent: request.user_agent.to_s.first(255),
            ip_hash: hash_ip(request.remote_ip), last_seen_at: Time.current)
    token
  end

  def self.find_active(token)
    return if token.blank?
    active.find_by(token_digest: digest(token))
  end

  def self.digest(token) = OpenSSL::Digest::SHA256.hexdigest(token)

  def self.hash_ip(ip)
    return if ip.blank?
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, ip).first(32)
  end

  def touch_if_stale!
    update_columns(last_seen_at: Time.current) if last_seen_at < TOUCH_INTERVAL.ago
  end

  def revoke! = update!(revoked_at: Time.current)

  def device_label
    ua = user_agent.to_s
    browser = ua[/(Edg|Firefox|Chrome|Safari|Opera)/, 1]&.sub("Edg", "Edge") || "Browser"
    os = ua[/(Windows|Android|iPhone|iPad|Mac OS X|Linux)/, 1]&.sub("Mac OS X", "macOS") || "unknown device"
    "#{browser} on #{os}"
  end
end
