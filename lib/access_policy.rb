require "access_policy/version"
require 'scoped_storage'

require 'access_policy/policy_check'
require 'access_policy/policy_enforcer'

module AccessPolicy

  def self.included(base)
    base.extend ClassMethods
  end

  def _default_error_policy
    ->(*){raise}
  end

  def _scope_storage
    ScopedStorage::ThreadLocalStorage
  end

  def _guard
    @_guard ||= PolicyCheck.new(default_error_policy: _default_error_policy,
                                scope_storage: _scope_storage
                               )
  end

  def _authorize(query)
    _guard.authorize self, query.to_sym
  end

  def with_user_or_role(user_or_role, error_policy =  _default_error_policy ,&block)
    _guard.with_user_or_role(user_or_role, error_policy, &block)
  end

  module ClassMethods

    def policy_guarded_method(action_name, &block)
      unsafe_action_name = :"#{action_name}_unsafe"

      define_method action_name do |*args|
        _authorize "#{action_name}?"
        self.send(unsafe_action_name, *args)
      end

      define_method unsafe_action_name, block
    end

  end

end
