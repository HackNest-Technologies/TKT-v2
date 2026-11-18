# Finds or creates the TKT account for a verified Google email.
# Linking to an existing account is allowed only because Google has verified the address.
class GoogleSignIn
  def self.find_or_create_user(uid:, email:)
    identity = Identity.find_by(provider: "google_oauth2", uid: uid)
    return identity.user if identity

    User.transaction do
      user = User.find_by(email: email) || User.new(email: email, password: SecureRandom.base58(32))
      if user.new_record?
        user.skip_confirmation!
        user.save!
      elsif !user.confirmed?
        user.confirm # Google verified the address
      end
      user.identities.create!(provider: "google_oauth2", uid: uid)
      user
    end
  end
end
