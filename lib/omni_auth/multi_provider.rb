# frozen_string_literal: true

require 'omniauth'

require 'omni_auth/multi_provider/handler'
require 'omni_auth/multi_provider/version'

module OmniAuth
  module MultiProvider
    def self.register(builder,
                      provider_name:,
                      path_prefix: ::OmniAuth.config.path_prefix,
                      **options, &dynamic_options_generator)

      handler = OmniAuth::MultiProvider::Handler.new(path_prefix: path_prefix,
                                                     **options,
                                                     &dynamic_options_generator)

      static_options = options.merge(path_prefix: path_prefix)

      builder.provider(provider_name, static_options.merge(handler.provider_options))
    end
  end
end
