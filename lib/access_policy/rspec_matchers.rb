module AccessPolicy
  module RspecMatchers
    extend ::RSpec::Matchers::DSL

    module Common
      def self.call(base)
        base.instance_eval do
          chain :to do |user|
            @user = user
          end

          chain :on do |object_to_guard|
            @object_to_guard = object_to_guard
          end

          define_method :permission_granted? do |policy_class, permission |
            policy = policy_class.new(@user, @object_to_guard)
            policy.public_send("#{permission}?")
          end

          define_method :permission_denied? do |*args|
            ! permission_granted?(*args)
          end

          define_method :object_as_text do
            @object_to_guard.nil? ? '' : " on #{@object_to_guard.inspect}"
          end

          define_method :user_as_text do
            @user.nil? ? '' : " for #{@user.inspect}"
          end

        end
      end

    end

    matcher :permit do |permission|
      match do |policy_class|
        permission_granted?(policy_class, permission)
      end

      failure_message_for_should do |policy_class|
        "#{policy_class} does not permit #{permission} #{object_as_text}#{user_as_text}."
      end

      failure_message_for_should_not do |policy_class|
        "#{policy_class} does not forbid #{permission}#{object_as_text}#{user_as_text}."
      end

      Common.call(self)

    end

    matcher :forbid do |permission|
      match do |policy_class|
        permission_denied?(policy_class, permission)
      end

      failure_message_for_should do |policy_class|
        "#{policy_class} does not forbid #{permission} #{object_as_text}#{user_as_text}."
      end

      failure_message_for_should_not do |policy_class|
        "#{policy_class} does not permit #{permission}#{object_as_text}#{user_as_text}."
      end

      Common.call(self)
    end
  end
end

RSpec.configure do |config|
  config.include AccessPolicy::RspecMatchers, :policy
end