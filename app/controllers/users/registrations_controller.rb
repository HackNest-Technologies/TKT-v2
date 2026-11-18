module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_permitted_parameters

    # Saves with the :registration context so age and consents are required.
    # Under-16 sign-ups are refused without storing anything.
    def create
      build_resource(sign_up_params)
      if User.under_minimum_age?(resource.birth_year)
        resource.errors.add(:birth_year, "shows you are under #{User::MINIMUM_AGE}. TKT accounts are for people aged #{User::MINIMUM_AGE} and over, but our streams and blog are open to everyone without an account.")
        clean_up_passwords(resource)
        return respond_with(resource)
      end

      resource.save(context: :registration)
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords(resource)
        set_minimum_password_length
        respond_with resource
      end
    end

    protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :birth_year, :confirm_minimum_age, :accept_terms, :accept_sensitive_data ])
      devise_parameter_sanitizer.permit(:account_update, keys: [])
    end

    def after_sign_up_path_for(_resource) = profile_setup_path
    def after_inactive_sign_up_path_for(_resource) = new_user_session_path

    # Password changes from settings revoke all other sessions (User callback revokes all;
    # we immediately start a fresh session for this browser).
    def update_resource(resource, params)
      changing_password = params[:password].present?
      updated = super
      if updated && changing_password
        SessionToken.write(warden, UserSession.start!(resource, request))
      end
      updated
    end

    def after_update_path_for(_resource) = account_path
  end
end
