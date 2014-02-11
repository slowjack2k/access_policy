require 'spec_helper'
require 'access_policy/rspec_matchers'

module MatcherExampleSpec
  DummyPolicy = Struct.new(:current_user, :object_to_guard) do
    def read?
      true
    end

    def write?
      current_user && current_user.allowed?
    end

    def destroy?
      write? && object_to_guard && !object_to_guard.locked?
    end
  end
end

describe "PolicyMatchers", type: :policy do
  subject(:policy){
    MatcherExampleSpec::DummyPolicy
  }


  context 'for a visitor' do
    let(:visitor){nil}

    it 'permits read' do
      expect(policy).to permit(:read).to(visitor)
    end

    it 'forbids write' do
      expect(policy).not_to permit(:write).to(visitor)
    end
  end

  context 'for a admin' do
    let(:admin){double('admin', allowed?: true)}
    let(:locked_object_to_guard){double('object to guard', locked?: true)}
    let(:unlocked_object_to_guard){double('object to guard', locked?: false)}

    it 'permits read' do
      expect(policy).to permit(:read).to(admin)
    end

    it 'permits write' do
      expect(policy).to permit(:write).to(admin)
    end

    it 'permits destroy for unlocked objects'  do
      expect(policy).to permit(:destroy).on(unlocked_object_to_guard).to(admin)
    end

    it 'forbids destroy for locked objects' do
      expect(policy).to forbid(:destroy).on(locked_object_to_guard).to(admin)
    end

  end

end