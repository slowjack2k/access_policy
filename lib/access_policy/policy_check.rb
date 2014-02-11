module AccessPolicy

  class PolicyCheck

    attr_accessor :default_error_policy, :scope_storage

    def initialize(default_error_policy: ->(*) { raise },
        scope_storage: ScopedStorage::ThreadLocalStorage)

      self.default_error_policy = default_error_policy
      self.scope_storage = scope_storage
    end


    def authorize(object_to_guard, action_to_guard, error_policy: default_error_policy)
      PolicyEnforcer.new(current_user_or_role_for_policy, object_to_guard, action_to_guard).authorize(error_policy) do
        self.policy_authorized=true
      end
    end

    def policy_for(object_or_class, error_policy = default_error_policy)
      PolicyEnforcer.new(current_user_or_role_for_policy, object_or_class).policy(error_policy)
    end

    def with_user_or_role(new_current_user_or_role_for_policy, error_policy = default_error_policy)
      self.policy_authorized = false

      switched_user_or_role(new_current_user_or_role_for_policy) do
        begin
          yield if block_given?
          raise(PolicyEnforcer::NotAuthorizedError, "#{new_current_user_or_role_for_policy}") unless policy_authorized?
        rescue => e
          error_policy.call(e)
        end
      end
    end

    def current_user_or_role_for_policy=(new_user)
      scope['current_user_or_role_for_policy'] = new_user
    end

    def current_user_or_role_for_policy
      scope['current_user_or_role_for_policy']
    end

    def policy_authorized=(new_value)
      scope['policy_authorized'] = new_value
    end

    def policy_authorized?
      !!policy_authorized
    end

    protected

    def policy_authorized
      scope['policy_authorized']
    end

    def scope
      @scope ||= ScopedStorage::Scope.new('policy_infos', scope_storage)
    end

    def switched_user_or_role(new_current_user_or_role_for_policy)
      old_current_user_or_role = self.current_user_or_role_for_policy
      self.current_user_or_role_for_policy = new_current_user_or_role_for_policy

      yield if block_given?

    ensure
      self.current_user_or_role_for_policy = old_current_user_or_role
    end

  end
end