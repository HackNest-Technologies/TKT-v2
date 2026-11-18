# Never write these to logs or error reports (partial, case-insensitive matches).
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :phone, :address, :message, :body, :contact, :dob, :birth, :session, :cookie, :authorization
]
