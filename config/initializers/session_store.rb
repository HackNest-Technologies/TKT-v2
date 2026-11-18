# Session cookie: HttpOnly, Secure in production, SameSite=Lax.
Rails.application.config.session_store :cookie_store,
  key: "_tkt_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 24.hours
