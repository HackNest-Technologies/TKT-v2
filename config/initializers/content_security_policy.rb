# Strict Content Security Policy. Scripts and styles must come from this origin
# or carry the per-request nonce; no inline event handlers, no eval.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.form_action :self, "https://accounts.google.com"
    policy.frame_ancestors :none
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
    policy.font_src    :self
    policy.img_src     :self, :data, "https://i.ytimg.com"
    policy.media_src   :self
    # Live streams are embedded from YouTube's privacy-enhanced domain only.
    policy.frame_src   "https://www.youtube-nocookie.com"
    # Turbo + Action Cable over the same origin.
    policy.connect_src(*[ :self, ("ws://localhost:3000" if Rails.env.development?) ].compact)
    policy.upgrade_insecure_requests true if Rails.env.production?
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
  config.content_security_policy_nonce_auto = true
end
