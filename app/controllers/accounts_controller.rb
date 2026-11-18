class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @sessions = current_user.user_sessions.active.order(last_seen_at: :desc)
    @current_session = UserSession.find_active(SessionToken.read(warden))
  end

  def export
    send_data JSON.pretty_generate(current_user.export_data),
              filename: "tkt-my-data-#{Date.current.iso8601}.json", type: "application/json", disposition: "attachment"
  end

  # Deletion: confirmed by password (or by typing the handle for Google-only members),
  # then the account is locked and purged after 30 days by AccountPurgeJob.
  def destroy
    if deletion_confirmed?
      current_user.request_deletion!
      sign_out(current_user)
      redirect_to root_path, notice: "Your account is scheduled for deletion and will be permanently removed in 30 days."
    else
      redirect_to account_path, alert: "That confirmation did not match, so your account was not deleted."
    end
  end

  private

  def deletion_confirmed?
    if current_user.google_only?
      ActiveSupport::SecurityUtils.secure_compare(params[:confirm_handle].to_s.delete_prefix("@").downcase, current_user.handle.to_s.downcase)
    else
      current_user.valid_password?(params[:current_password].to_s)
    end
  end
end
