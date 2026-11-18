# Deny powerful browser features the site never uses.
Rails.application.config.permissions_policy do |policy|
  policy.camera      :none
  policy.microphone  :none
  policy.geolocation :none
  policy.usb         :none
  policy.payment     :none
  policy.gyroscope   :none
  policy.accelerometer :none
  policy.fullscreen :self, "https://www.youtube-nocookie.com"
end
