module AccessPolicy
  module RspecMatchers
    extend ::RSpec::Matchers::DSL


    def self.included(base)
      base.metadata[:type] = :policy
    end

    class PositivePolicyMatcher
      attr_accessor :policy_class, :user, :object_to_guard, :permission

      def initialize(permission)
        self.permission = permission
      end

      def matches?(policy_class)
        self.policy_class = policy_class
        eval_match
      end

      def eval_match
        permission_granted?
      end

      def failure_message
        "#{policy_class} #{failure_message_part} '#{permission}'#{object_as_text}#{user_as_text}."
      end

      def negative_failure_message
        "#{policy_class} #{negative_failure_message_part} '#{permission}'#{object_as_text}#{user_as_text}."
      end


      def failure_message_part
        'does not permit'
      end

      def negative_failure_message_part
        'does not forbid'
      end

      def to(user)
        self.user = user
        self
      end
      alias_method :for, :to
      alias_method :for_user, :to
      alias_method :to_user, :to

      def on(object_to_guard)
        self.object_to_guard = object_to_guard
        self
      end
      alias_method :with, :on

      protected

      def permission_granted?
        policy = policy_class.new(@user, @object_to_guard)
        policy.public_send("#{permission}?")
      end

      def object_as_text
        self.object_to_guard.nil? ? '' : " on #{self.object_to_guard.inspect}"
      end

      def  user_as_text
        self.user.nil? ? '' : " to #{self.user.inspect}"
      end

    end

    class NegativePolicyMatcher < PositivePolicyMatcher
      def eval_match
        permission_denied?
      end

      def failure_message_part
        'does not forbid'
      end

      def negative_failure_message_part
        'does permit'
      end

      protected

      def permission_denied?
        ! permission_granted?
      end
    end

    def permit(expected=nil)
      PositivePolicyMatcher.new(expected)
    end

    def forbid(expected=nil)
      NegativePolicyMatcher.new(expected)
    end

  end
end

RSpec.configure do |config|
  config.include AccessPolicy::RspecMatchers, type: :policy, example_group: ->(example_group, metadata){
    metadata[:type].nil? && %r{spec/policies} =~ example_group[:file_path]
  }
end