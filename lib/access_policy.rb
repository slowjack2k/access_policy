require "access_policy/version"
require 'scoped_storage'

require 'access_policy/policy_check'
require 'access_policy/policy_enforcer'

module AccessPolicy

  class NestedStandardError < StandardError
    attr_reader :original
    def initialize(msg, original=$!)
      super(msg)
      @original = original
    end
  end

  class NotDefinedError < NestedStandardError
  end

  class NotAuthorizedError < NestedStandardError
  end

  class AuthorizeNotCalledError < NestedStandardError
  end

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

    def policy_guarded_method(action_name, query="#{action_name}?" ,&block)
      unsafe_action_name = unsafe_action_name(action_name)

      define_method action_name do |*args|
        _authorize query
        self.send(unsafe_action_name, *args)
      end

      define_method unsafe_action_name, block
    end

    def unsafe_action_name(action_name)
      :"#{action_name}_unsafe"
    end

  end

end
