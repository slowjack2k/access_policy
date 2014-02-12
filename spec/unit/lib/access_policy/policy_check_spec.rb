require 'spec_helper'

module PolicyCheckSpec
  class Dummy

  end

  DummyPolicy = Struct.new(:current_user, :object_to_guard) do
    def call?
      true
    end
  end
end

module AccessPolicy
  describe PolicyCheck do
    subject {
      AccessPolicy::PolicyCheck.new.tap { |p|
        p.current_user_or_role_for_policy=nil
        p.policy_authorize_called = true
      }

    }

    let(:current_user) {
      "It's me"
    }


    describe '.policy_for' do

      it 'returns a policy object for a class' do
        expect(subject.policy_for(PolicyCheckSpec::Dummy)).to be_kind_of PolicyCheckSpec::DummyPolicy
      end

      it 'returns a policy object for a object' do
        expect(subject.policy_for(PolicyCheckSpec::Dummy.new)).to be_kind_of PolicyCheckSpec::DummyPolicy
      end

      it 'sets the current user' do
        subject.current_user_or_role_for_policy = current_user
        expect(subject.policy_for(PolicyCheckSpec::Dummy.new).current_user).to be current_user
      end

      it 'uses my error handler' do
        object_to_guard = Object.new
        error_handler=double('error handler')
        expect(error_handler).to receive(:call).with(object_to_guard)

        subject.policy_for(object_to_guard, error_handler)
      end
    end

    describe '.with_user_or_role' do
      it 'sets the current user' do
        subject.with_user_or_role(current_user) do
          subject.policy_authorize_called = true
          expect(subject.current_user_or_role_for_policy).to eq current_user
        end
      end

      it 'sets the current user back after execution' do
        subject.current_user_or_role_for_policy = 'other user'

        subject.with_user_or_role(current_user) do
          subject.policy_authorize_called = true
        end

        expect(subject.current_user_or_role_for_policy).to eq 'other user'
      end

      it 'raises PolicyEnforcer::AuthorizeNotCalledError when authorize is not called' do
        expect { subject.with_user_or_role(current_user) }.to raise_error AccessPolicy::AuthorizeNotCalledError
      end

      it 'does not raise PolicyEnforcer::NotAuthorizedError when authorize is called' do
        expect {
          subject.with_user_or_role(current_user) do
            subject.authorize(PolicyCheckSpec::Dummy.new, "call")
          end
        }.not_to raise_error
      end

      it 'uses an custom an error handler' do
        error_handler=double('error handler')
        expect(error_handler).to receive(:call).with(kind_of(StandardError))

        subject.with_user_or_role(current_user, error_handler)
      end

      it 'supports nested context switches' do
        user1 = 'user 1'
        user2 = 'user 2'
        user3 = 'user 3'

        subject.current_user_or_role_for_policy = user1

        subject.with_user_or_role(user2, ->(*){}) do
          expect(subject.current_user_or_role_for_policy).to eq user2

          subject.with_user_or_role(user3) do
            expect(subject.current_user_or_role_for_policy).to eq user3
          end

          expect(subject.current_user_or_role_for_policy).to eq user2
        end

        expect(subject.current_user_or_role_for_policy).to eq user1

      end

    end

    describe '.authorize' do
      it 'returns true when the user is authorized' do
        expect(subject.authorize(PolicyCheckSpec::Dummy.new, "call")).to be == true
      end

      it 'raises an exception when no method is defined' do
        expect { subject.authorize(PolicyCheckSpec::Dummy.new, "call2") }.to raise_error
      end

      it 'uses a given error handler' do
        object_to_guard = PolicyCheckSpec::Dummy.new
        error_handler=double('error handler')
        expect(error_handler).to receive(:call).with(object_to_guard)

        subject.authorize(object_to_guard, "call2", error_policy: error_handler)
      end
    end

  end
end