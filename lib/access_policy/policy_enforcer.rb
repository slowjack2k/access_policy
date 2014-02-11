module AccessPolicy
  class PolicyEnforcer
    class NotDefinedError < StandardError;
    end
    class NotAuthorizedError < StandardError;
    end

    attr_accessor :current_user_or_role, :object_or_class, :query, :default_error_policy

    def initialize(current_user_or_role, object_or_class, query=nil, default_error_policy=->(*) { raise })
      raise NotDefinedError, 'unable to find policy class for anonymous classes' if class_to_guard(current_user_or_role).name.nil? || class_to_guard(current_user_or_role).name.length < 1

      self.current_user_or_role = current_user_or_role
      self.object_or_class = object_or_class
      self.query = query
      self.default_error_policy = default_error_policy

    end

    def authorize(error_policy=default_error_policy)
      raise(PolicyEnforcer::NotAuthorizedError, "not allowed to #{query} this #{object_or_class}" ) unless _guard_action()
      yield true if block_given?
      true
    rescue
      error_policy.call(object_or_class)
    end

    def policy(error_policy=default_error_policy)
      specific_policy_for_class.new(current_user_or_role, object_or_class)
    rescue
      error_policy.call(object_or_class)
    end

    def query=(new_query)
      new_query = new_query.to_s
      @query = (new_query.end_with?('?') ? new_query : "#{new_query}?").to_sym
    end

    protected

    def class_to_guard(obj_or_class=object_or_class)
      obj_or_class.is_a?(Class) ? obj_or_class : obj_or_class.class
    end

    def default_policy_name
      "#{class_to_guard.name}Policy"
    end

    def _guard_action
      policy(->(*) { raise }).public_send(query)
    rescue NoMethodError
      raise NotDefinedError, "unable to find policy method #{query} for #{policy}"
    end

    def specific_policy_for_class

      policy_class = class_to_guard.policy_class if class_to_guard.respond_to? :policy_class
      policy_class || Object.const_get(default_policy_name, false)
    rescue
      raise NotDefinedError, "unable to find policy class #{default_policy_name}"
    end


  end
end