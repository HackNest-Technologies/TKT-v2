class Consent < ApplicationRecord
  PURPOSES = %w[terms_and_privacy sensitive_data_processing].freeze
  belongs_to :user
  validates :purpose, inclusion: { in: PURPOSES }
  validates :version, :granted_at, presence: true

  def readonly? = persisted? && !withdrawn_at_changed? # append-only apart from withdrawal
end
