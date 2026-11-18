# OmniAuth requests must be POSTs with a CSRF token (omniauth-rails_csrf_protection).
OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.logger = Rails.logger
