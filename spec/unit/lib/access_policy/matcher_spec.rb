require 'spec_helper'
require 'access_policy/rspec_matchers'

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
  end
end