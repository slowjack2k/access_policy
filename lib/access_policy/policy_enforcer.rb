module AccessPolicy
  class PolicyEnforcer

    attr_accessor :current_user_or_role, :object_or_class, :query, :default_error_policy

    def initialize(current_user_or_role, object_or_class, query=nil, default_error_policy=->(*) { raise })
      raise NotDefinedError, 'unable to find policy class for anonymous classes' unless policy_class_can_be_found_for?(object_or_class)

      self.current_user_or_role = current_user_or_role
      self.object_or_class = object_or_class
      self.query = query
      self.default_error_policy = default_error_policy

    end

    def authorize(error_policy=default_error_policy)
      unless _guard_action()
        error_message = policy.respond_to?(:error_message) ? policy.error_message : "not allowed to #{query} this #{object_or_class}"
        raise(AccessPolicy::NotAuthorizedError, error_message)
      end
      yield true if block_given?
      true
    rescue
      error_policy.call(object_or_class)
    end

    def policy(error_policy=default_error_policy)
      @policy||= specific_policy_for_class.new(current_user_or_role, object_or_class)
    rescue
      error_policy.call(object_or_class)
    end

    def query=(new_query)
      new_query = new_query.to_s
      @query = (new_query.end_with?('?') ? new_query : "#{new_query}?").to_sym
    end

    protected

    def policy_class_can_be_found_for?(object_or_class)
      subject = class_to_guard(object_or_class)
      (!subject.name.nil? && subject.name.length > 0) || subject.respond_to?(:policy_class)
    end

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