# Headers beyond Rails' defaults. HSTS is sent by force_ssl in production.
Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Frame-Options" => "DENY",
  "X-Content-Type-Options" => "nosniff",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Cross-Origin-Opener-Policy" => "same-origin",
  "X-Permitted-Cross-Domain-Policies" => "none",
  # Modern syntax; Rails 8.1 itself only emits the legacy Feature-Policy header.
  "Permissions-Policy" => 'camera=(), microphone=(), geolocation=(), usb=(), payment=(), gyroscope=(), accelerometer=(), fullscreen=(self "https://www.youtube-nocookie.com")'
)
