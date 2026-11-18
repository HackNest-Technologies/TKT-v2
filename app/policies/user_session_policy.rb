class UserSessionPolicy < ApplicationPolicy
  def destroy? = user.present? && record.user_id == user.id
  def revoke_others? = user.present?

  class Scope < Scope
    def resolve = user ? scope.where(user_id: user.id) : scope.none
  end
end
