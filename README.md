# OmniAuth MultiProvider

This is a simple extension to [omniauth](https://github.com/omniauth/omniauth) for supporting 
multiple identity provider instances of a given type e.g. multiple SAML or OAuth2
identity providers. It is a generalization of the 
[omniauth-multi-provider-saml](https://github.com/salsify/omniauth-multi-provider-saml).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-multi-provider'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-multi-provider

## Setup

**Getting your setup to work with a single identity provider before attempting to use this gem is highly recommended.** 

The setup process consists of the following steps:

1. Create an OmniAuth callback controller for your identity provider like you normally would with OmniAuth.
1. Configure your routes to handle routes for multiple identity provider instances.
1. Configure omniauth-multi-provider to choose the appropriate identity provider instance.

### Configure Routes

Add something like the following to your routes assuming you're using Rails and a SAML identity provider 
(your actual URL structure may vary):

```ruby
MyApplication::Application.routes.draw do
  match '/auth/saml/:identity_provider_id/callback',
        via: [:get, :post],
        to: 'omniauth_callbacks#saml',
        as: 'user_omniauth_callback'

  match '/auth/saml/:identity_provider_id',
        via: [:get, :post],
        to: 'omniauth_callbacks#passthru',
        as: 'user_omniauth_authorize'
end
```

### Configure OmniAuth

The basic configuration of OmniAuth looks something like this:

```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth::MultiProvider.register(self,
                                   provider_name: :saml,
                                   identity_provider_id_regex: /\d+/,
                                   path_prefix: '/auth/saml',
                                   callback_suffix: 'callback',
                                   # Specify any additional provider specific options
                                   name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
                                   issuer: 'salsify.com',
                                   allowed_clock_drift: 5.seconds) do |identity_provider_id, rack_env|
    identity_provider = SAML::IdentityProvider.find(identity_provider_id)
    # Optionally store a reference to the identity provider in the Rack environment
    # so you can reference it in your OmniAuth callbacks controller
    rack_env['salsify.saml_identity_provider'] = identity_provider
    # Any dynamic options returned by this block will be merged in with any statically
    # configured options for the identity provider type e.g. issuer in this example.
    identity_provider.options
  end
  
  # This also works with multiple provider types
  OmniAuth::MultiProvider.register(self,
                                   provider_name: :oauth2,
                                   identity_provider_id_regex: /\d+/,
                                   path_prefix: '/auth/oauth2') do |identity_provider_id, rack_env|
    identity_provider = OAuth2::IdentityProvider.find(identity_provider_id)
    rack_env['salsify.oauth2_identity_provider'] = identity_provider
    identity_provider.options
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org)
.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/salsify/omniauth-multi-provider.## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

