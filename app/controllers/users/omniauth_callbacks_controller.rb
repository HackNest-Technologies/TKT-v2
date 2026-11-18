module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      auth = request.env["omniauth.auth"]
      email = auth.dig("info", "email").to_s.downcase
      verified = auth.dig("extra", "raw_info", "email_verified").to_s == "true"

      unless verified && email.present?
        redirect_to new_user_session_path, alert: "Google did not confirm that email address. Please sign up with email and password instead."
        return
      end

      user = GoogleSignIn.find_or_create_user(uid: auth["uid"].to_s, email: email)
      if user.active_for_authentication?
        sign_in_and_redirect user, event: :authentication
        set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
      else
        redirect_to new_user_session_path, alert: I18n.t("devise.failure.#{user.inactive_message}")
      end
    end

    def failure
      redirect_to new_user_session_path, alert: "Google sign-in was cancelled or failed. Please try again."
    end
  end
end
