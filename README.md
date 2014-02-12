# AccessPolicy [![Code Climate](https://codeclimate.com/github/slowjack2k/access_policy.png)](https://codeclimate.com/github/slowjack2k/access_policy) [![Build Status](https://travis-ci.org/slowjack2k/access_policy.png?branch=master)](https://travis-ci.org/slowjack2k/access_policy) [![Coverage Status](https://coveralls.io/repos/slowjack2k/access_policy/badge.png?branch=master)](https://coveralls.io/r/slowjack2k/access_policy?branch=master) [![Gem Version](https://badge.fury.io/rb/access_policy.png)](http://badge.fury.io/rb/access_policy)

Object oriented authorization for ruby. It provides helper to
protect method call's via Policy-Classes.

Inspired by https://github.com/elabs/pundit, but without Rails
and with a threat local storage for the current user or role.

## Installation

Add this line to your application's Gemfile:

    gem 'access_policy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install access_policy

## Usage

```ruby

class ToGuard
  def method_to_guard

  end
end

ToGuardPolicy = Struct.new(:current_user_or_role, :object_of_kind_to_guard) do

  attr_accessor :error_message # optional

  def method_to_guard?
    if current_user_or_role.is_allowed?
      true
    else
      self.error_message = "you'r not allowed to do this" # optional
      false
    end
  end

end

object_to_guard = ToGuard.new

policy_checker = AccessPolicy::PolicyCheck.new

policy_checker.current_user_or_role_for_policy = current_user

policy_checker.with_user_or_role(current_user) do
  begin
    policy_checker.authorize(object_to_guard, 'method_to_guard')
    object_to_guard.method_to_guard
  rescue AccessPolicy::NotAuthorizedError
   ...
  rescue AccessPolicy::NotDefinedError
   ...
  end
end


```

Or

```ruby

 class ToGuard
   include AccessPolicy

   policy_guarded_method 'method_to_guard' do
     # do some stuff
   end

    policy_guarded_method 'publish', 'create?' do
      # do some stuff
    end

 end

 ToGuardPolicy = Struct.new(:current_user_or_role, :object_of_kind_to_guard) do

   def method_to_guard?
     current_user_or_role.is_allowed?
   end

 end

 object_to_guard = ToGuard.new

 object_to_guard.with_user_or_role(current_user) do
   begin
     object_to_guard.method_to_guard
   rescue AccessPolicy::NotAuthorizedError
    ...
   rescue AccessPolicy::NotDefinedError
    ...
   end
 end

 object_to_guard.with_user_or_role(current_user) do
    begin
      object_to_guard.method_to_guard

      object_to_guard.with_user_or_role(current_user.as_root) do
        object_to_guard.method_to_guard_for_root
      end

    rescue AccessPolicy::NotAuthorizedError
     ...
    rescue AccessPolicy::NotDefinedError
     ...
    end
  end


```

Test policies with rspec:

```ruby

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


```

## Contributing

1. Fork it ( http://github.com/slowjack2k/access_policy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
