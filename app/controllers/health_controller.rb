# /health: process is up AND the database answers. Used by external uptime checks.
# No details are returned to the caller; failures are logged.
class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")
    render plain: "ok", status: :ok
  rescue StandardError => e
    Rails.logger.error("health_check_failed error_class=#{e.class.name}")
    render plain: "unavailable", status: :service_unavailable
  end
end
