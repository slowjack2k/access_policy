require 'spec_helper'

module AccessPolicySpec
  DummyPolicy = Struct.new(:current_user, :object_to_guard) do
    def call?
      current_user && current_user.allowed?
    end

    def query?
      raise StandardError, 'query? called'
    end
  end


  class Dummy
    include AccessPolicy

    policy_guarded_method 'call' do
      :return_value
    end

    policy_guarded_method 'other_method_name', 'query?' do
      :return_value
    end

  end
end

describe AccessPolicy do
  subject{
    AccessPolicySpec::Dummy.new
  }

  let(:falsy_user){
    double("user", allowed?: false)
  }

  let(:truethy_user){
    double("user", allowed?: true)
  }



  describe '.policy_guarded_method' do
    it 'creates a guarded method' do
      expect(subject).to respond_to :call
    end

    it 'protects created methods' do
      expect {
        subject.with_user_or_role(falsy_user) do
          subject.call
        end
      }.to  raise_error AccessPolicy::NotAuthorizedError
    end

    it 'grands access to guarded methods when the user has the right' do
      expect {
        subject.with_user_or_role(truethy_user) do
          subject.call
        end
      }.not_to  raise_error
    end

    it 'creates a not guarded method' do
      expect(subject).to respond_to :call_unsafe
    end

    it 'does not protect unsafe methods' do
      expect {
        subject.call_unsafe
      }.not_to  raise_error
    end

    it 'uses a different name for query when wanted' do
      expect {
        subject.other_method_name
      }.to  raise_error(StandardError, 'query? called')
    end
  end

  describe '.with_user_or_role' do
    it 'delegates to the policy check object' do
      error_policy = ->(exception){}
      current_user = double('user')
      expect(subject._guard).to receive(:with_user_or_role).with(current_user, error_policy)

      subject.with_user_or_role(current_user, error_policy)
    end
  end

end