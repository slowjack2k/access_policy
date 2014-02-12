require 'spec_helper'

module PolicyEnforcerSpec
  class Dummy

  end

  DummyPolicy = Struct.new(:current_user, :object_to_guard) do
    def call?
      true
    end

    def not_allowed_call?
      false
    end

    def error_message
      "some thing went wrong"
    end
  end

  module A
    class Dummy

    end

    DummyPolicy = Struct.new(:d_current_user, :d_object_to_guard)
  end
end

module AccessPolicy
  describe PolicyEnforcer do
    subject {
      AccessPolicy::PolicyEnforcer.new(current_user, object_to_guard, action, error_policy)
    }

    let(:current_user) {
      double('user')
    }

    let(:object_to_guard) {
      PolicyEnforcerSpec::Dummy.new
    }

    let(:action) {
      "call"
    }

    let(:error_policy) {
      ->(*) { raise }
    }

    describe '#new' do
      it 'raises an error when class to guard has no name' do
        expect{AccessPolicy::PolicyEnforcer.new(current_user, Class.new.new, action, error_policy)}.to raise_error
      end

      it 'raises no error when class to guard has no name but an policy class is defined' do
        some_class = Class.new do
          def self.policy_class
            Class.new
          end
        end

        expect { AccessPolicy::PolicyEnforcer.new(current_user, some_class.new, action, error_policy) }.not_to raise_error
      end
    end


    describe '.policy' do

      it 'returns a policy object for a class' do
        subject.object_or_class = PolicyEnforcerSpec::Dummy
        expect(subject.policy).to be_kind_of PolicyEnforcerSpec::DummyPolicy
      end

      it 'returns a policy object for a object' do
        expect(subject.policy).to be_kind_of PolicyEnforcerSpec::DummyPolicy
      end

      it 'sets the current user' do
        expect(subject.policy.current_user).to be current_user
      end

      it 'uses my error handler' do
        object_to_guard = Object.new
        error_handler=double('error handler')
        expect(error_handler).to receive(:call).with(object_to_guard)

        subject.object_or_class = object_to_guard

        subject.policy(error_handler)
      end


      it 'returns a policy object for a class within a module' do
        subject.object_or_class = PolicyEnforcerSpec::A::Dummy.new
        expect(subject.policy).to be_kind_of PolicyEnforcerSpec::A::DummyPolicy
      end

      it 'raises Policy::NotDefinedError when no policy class found' do
        B = Object
        subject.object_or_class = B
        expect { subject.policy }.to raise_error AccessPolicy::NotDefinedError
      end

      it 'raises Policy::NotDefinedError when class.name is empty' do
        subject.object_or_class = Class.new
        expect { subject.policy }.to raise_error AccessPolicy::NotDefinedError
      end
    end

    describe '.authorize' do
      it 'returns true when the user is authorized' do
        expect(subject.authorize).to be == true
      end

      it 'raises an exception when the user is not authorized' do
        subject.query = "not_allowed_call"
        expect{subject.authorize}.to raise_error
      end

      it 'sets custom error messages on the error' do
        subject.query = "not_allowed_call"
        expect{subject.authorize}.to raise_error(AccessPolicy::NotAuthorizedError, "some thing went wrong")
      end

      it 'raises an exception when no method is defined' do
        subject.query = "call2"
        expect { subject.authorize }.to raise_error AccessPolicy::NotDefinedError
      end

      it 'uses a given error handler' do
        object_to_guard = Object.new
        error_handler=double('error handler')
        expect(error_handler).to receive(:call).with(object_to_guard)

        subject.object_or_class = object_to_guard

        subject.authorize(error_handler)
      end

      it 'yields when authorize was successful' do
        expect { |block| subject.authorize(&block) }.to yield_with_args(true)
      end

      it 'does not yield when authorize was not successful' do
        subject.query = "call2"
        expect { |block| subject.authorize(->(*) {}, &block) }.not_to yield_with_args
      end
    end

  end
end