# "Pick a handle" step (design: Trybe path 7). Also collects age and consents when
# they are missing, which happens for members who joined with Google.
class ProfileSetupController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.assign_attributes(profile_params)
    if User.under_minimum_age?(@user.birth_year)
      current_user.request_deletion!
      sign_out(current_user)
      redirect_to root_path, alert: "TKT accounts are for people aged #{User::MINIMUM_AGE} and over, so this account has been closed. Our streams and blog are open to everyone."
    elsif @user.save(context: :profile)
      redirect_to account_path, notice: "Welcome to the Trybe, @#{@user.handle}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    permitted = [ :handle ]
    permitted += [ :birth_year, :confirm_minimum_age ] if current_user.birth_year.blank?
    permitted << :accept_terms if current_user.terms_accepted_at.blank?
    permitted << :accept_sensitive_data if current_user.sensitive_data_consent_at.blank?
    params.expect(user: permitted)
  end
end
