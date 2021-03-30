# frozen_string_literal: true

describe OmniAuth::MultiProvider do
  describe ".register" do
    let(:builder) { instance_double(OmniAuth::Builder, provider: nil) }
    let(:provider_name) { :my_provider }
    let(:path_prefix) { '/auth' }
    let(:identity_provider_id_regex) { /\d+/ }
    let(:static_provider_options) do
      {
        foo: 'bar'
      }
    end

    before do
      described_class.register(builder, provider_name: provider_name, path_prefix: path_prefix,
                               identity_provider_id_regex: identity_provider_id_regex, **static_provider_options) do
        nil
      end
    end

    it "registers the provider with static provider options" do
      expect(builder).to have_received(:provider).with(provider_name, hash_including(static_provider_options))
    end

    it "registers the provider with setup, request_path, and callback_path options" do
      expect(builder).to have_received(:provider).with(provider_name,
                                                       hash_including(:setup, :request_path, :callback_path))
    end
  end
end
