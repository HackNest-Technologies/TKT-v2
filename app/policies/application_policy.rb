class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Deny by default.
  %i[index? show? create? new? update? edit? destroy?].each { |m| define_method(m) { false } }

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve = scope.none

    private

    attr_reader :user, :scope
  end
end
