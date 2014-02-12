require 'spec_helper'
require 'access_policy/rspec_matchers'

module RspecMatchersSpec
  DummyPolicy = Struct.new(:current_user, :object_to_guard) do
    def read?
      true
    end

    def write?
      false
    end
  end
end

describe 'PolicyMatchers' do
  context 'none policy spec' do
    it 'has no access to permit' do
      expect { permit }.to raise_error(NameError)
    end

    it 'has no access to forbid' do
      expect { forbid }.to raise_error(NameError)
    end
  end

  context 'policy spec', type: :policy do
    it 'grands access to permit' do
      expect { permit }.not_to raise_error
    end

    it 'grands access to forbid' do
      expect { forbid }.not_to raise_error
    end


    context 'permit' do
      let(:record){'a record'}
      let(:user){'a user'}

      it 'returns true when permission in granted' do
        matcher = permit(:read).on(record).to(user)
        expect(matcher.matches?(RspecMatchersSpec::DummyPolicy)).to be_truthy
      end

      it 'sets error messages' do
        matcher = permit(:read).on(record).to(user)
        matcher.matches?(RspecMatchersSpec::DummyPolicy)

        expect(matcher.failure_message).to eq %q{RspecMatchersSpec::DummyPolicy does not permit 'read' on "a record" to "a user".}
        expect(matcher.negative_failure_message).to eq %q{RspecMatchersSpec::DummyPolicy does not forbid 'read' on "a record" to "a user".}
      end

      it 'returns false when permission is not granted' do
        matcher = permit(:write).on(record).to(user)
        expect(matcher.matches?(RspecMatchersSpec::DummyPolicy)).to be_falsy
      end
    end

    context 'forbid' do
      let(:record){'a record'}
      let(:user){'a user'}

      it 'returns false when permission in granted' do
        matcher = forbid(:read).on(record).to(user)
        expect(matcher.matches?(RspecMatchersSpec::DummyPolicy)).to be_falsy
      end

      it 'returns true when permission is not granted' do
        matcher = forbid(:write).on(record).to(user)
        expect(matcher.matches?(RspecMatchersSpec::DummyPolicy)).to be_truthy
      end

      it 'sets error messages' do
        matcher = forbid(:read).on(record).to(user)
        matcher.matches?(RspecMatchersSpec::DummyPolicy)

        expect(matcher.failure_message).to eq %q{RspecMatchersSpec::DummyPolicy does not forbid 'read' on "a record" to "a user".}
        expect(matcher.negative_failure_message).to eq %q{RspecMatchersSpec::DummyPolicy does permit 'read' on "a record" to "a user".}
      end
    end
  end
end