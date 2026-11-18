# Ties each Devise sign-in to a server-side UserSession so it can be listed and revoked.
#
# The token is read from Warden's raw session hash, not warden.session(:user):
# the latter re-checks authentication and would recurse inside logout callbacks.
SESSION_TOKEN_KEY = "tkt_session_token".freeze

module SessionToken
  KEY = "warden.user.user.session".freeze

  def self.read(warden) = (warden.raw_session[KEY] || {})[SESSION_TOKEN_KEY]

  def self.write(warden, token)
    (warden.raw_session[KEY] ||= {})[SESSION_TOKEN_KEY] = token
  end
end

Warden::Manager.after_set_user except: :fetch do |user, warden, opts|
  next unless opts[:scope] == :user && user.is_a?(User)
  next if opts[:store] == false
  SessionToken.write(warden, UserSession.start!(user, ActionDispatch::Request.new(warden.env)))
end

Warden::Manager.after_set_user only: :fetch do |user, warden, opts|
  next unless opts[:scope] == :user && user.is_a?(User)
  record = UserSession.find_active(SessionToken.read(warden))
  if record.nil? || record.user_id != user.id
    warden.logout(:user)
    throw :warden, scope: :user, message: :session_revoked
  end
  record.touch_if_stale!
end

Warden::Manager.before_logout do |user, warden, opts|
  next unless opts[:scope] == :user && user.is_a?(User)
  UserSession.find_active(SessionToken.read(warden))&.revoke!
end
