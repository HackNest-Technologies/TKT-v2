# One JSON line per request: route, status, timings, request id. No params.
Rails.application.configure do
  config.lograge.enabled = !Rails.env.development?
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.ignore_actions = [ "Rails::HealthController#show", "HealthController#show" ]
  config.lograge.custom_payload do |controller|
    { request_id: controller.request.request_id }
  end
end
