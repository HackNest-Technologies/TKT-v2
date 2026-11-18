class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :preview_gate
  before_action :require_profile_completion
  layout :layout_by_resource

  rescue_from Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound, with: :not_found

  private

  # Preview hosting (Render) sits behind a shared password so the unfinished site is not public.
  def preview_gate
    password = ENV["PREVIEW_PASSWORD"]
    return if password.blank?
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    authenticate_or_request_with_http_basic("TKT preview") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("PREVIEW_USER", "tkt")) &
        ActiveSupport::SecurityUtils.secure_compare(pass, password)
    end
  end

  def require_profile_completion
    return unless user_signed_in? && current_user.profile_incomplete?
    return if devise_controller? || is_a?(ProfileSetupController)
    redirect_to profile_setup_path
  end

  def after_sign_in_path_for(resource)
    resource.is_a?(User) && resource.profile_incomplete? ? profile_setup_path : stored_location_for(resource) || account_path
  end

  def layout_by_resource
    devise_controller? && !(controller_name == "registrations" && action_name.in?(%w[edit update])) ? "auth" : "application"
  end

  # Same response for "not yours" and "does not exist", so IDs cannot be probed.
  def not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
