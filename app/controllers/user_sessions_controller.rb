class UserSessionsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    record = policy_scope(UserSession).active.find(params[:id])
    authorize record
    record.revoke!
    redirect_to account_path, notice: "That session has been signed out."
  end

  # "Sign out everywhere else": keeps this browser signed in.
  def others
    authorize UserSession, :revoke_others?
    current = UserSession.find_active(SessionToken.read(warden))
    current_user.revoke_all_sessions!(except: current)
    redirect_to account_path, notice: "All other sessions have been signed out."
  end
end
