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

  def method_to_guard?
    current_user_or_role.is_allowed?
  end

end

object_to_guard = ToGuard.new

policy_checker = AccessPolicy::PolicyCheck.new

policy_checker.current_user_or_role_for_policy = current_user

policy_checker.with_user_or_role(current_user) do
  begin
    policy_checker.authorize(object_to_guard, 'method_to_guard')
    object_to_guard.method_to_guard
  rescue AccessPolicy::PolicyEnforcer::NotAuthorizedError
   ...
  rescue AccessPolicy::PolicyEnforcer::NotDefinedError
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
   rescue PolicyEnforcer::NotAuthorizedError
    ...
   rescue PolicyEnforcer::NotDefinedError
    ...
   end
 end

 object_to_guard.with_user_or_role(current_user) do
    begin
      object_to_guard.method_to_guard

      object_to_guard.with_user_or_role(current_user.as_root) do
        object_to_guard.method_to_guard_for_root
      end

    rescue PolicyEnforcer::NotAuthorizedError
     ...
    rescue PolicyEnforcer::NotDefinedError
     ...
    end
  end


```

## Contributing

1. Fork it ( http://github.com/slowjack2k/access_policy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
