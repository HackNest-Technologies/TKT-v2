class Identity < ApplicationRecord
  belongs_to :user
  validates :provider, inclusion: { in: %w[google_oauth2] }
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
