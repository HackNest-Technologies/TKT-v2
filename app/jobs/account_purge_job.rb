# Permanently deletes accounts 30 days after the member asked for deletion.
class AccountPurgeJob < ApplicationJob
  queue_as :default
  GRACE_PERIOD = 30.days

  def perform
    User.where(deletion_requested_at: ...GRACE_PERIOD.ago).find_each(&:destroy!)
  end
end
