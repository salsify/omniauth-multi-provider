describe OmniAuth::MultiProvider::Handler do
  let(:dynamic_provider_options) do
    {
      foo: 'bar'
    }
  end

  let(:provider_options_generator) do
    Proc.new { dynamic_provider_options }
  end

  let(:path_prefix) { '/auth/saml' }
  let(:handler) do
    described_class.new(path_prefix: path_prefix, identity_provider_id_regex: /\d+/, **handler_options, &provider_options_generator)
  end

  let(:handler_options) do
    {}
  end

  let(:strategy) do
    instance_double(OmniAuth::Strategy, options: {})
  end

  let(:provider_id) { 12345 }
  let(:path) { "#{path_prefix}/#{provider_id}" }

  let(:env) do
    {
      'omniauth.strategy' => strategy,
      'PATH_INFO' => path
    }
  end

  describe "#provider_options" do
    it "returns a hash with setup, request_path, callback_path" do
      expect(handler.provider_options).to eq(setup: handler.method(:setup),
                                             request_path: handler.method(:request_path?),
                                             callback_path: handler.method(:callback_path?))
    end
  end

  describe "#setup" do
    shared_examples_for "it does not set any strategy options" do
      specify do
        expect(strategy.options.keys).to contain_exactly(:request_path, :callback_path)
      end
    end

    context "when the request path has a valid provider id" do
      before do
        handler.setup(env)
      end

      it "sets the strategy's request path" do
        expect(strategy.options[:request_path]).to eq("#{path_prefix}/#{provider_id}")
      end

      it "sets the strategy's callback path" do
        expect(strategy.options[:callback_path]).to eq("#{path_prefix}/#{provider_id}/callback")
      end

      it "adds the options returned by the identity_provider_options_generator to the strategy's options" do
        expect(strategy.options).to include(dynamic_provider_options)
      end
    end

    context "when the request path does not match a valid provider id" do
      let(:provider_id) { 'invalid' }

      before do
        handler.setup(env)
      end

      it "does not set any strategy options" do
        expect(strategy.options).to be_empty
      end
    end

    context "when the identity_provider_options_generator returns nil" do
      let(:dynamic_provider_options) {}

      before do
        handler.setup(env)
      end

      it "only sets the request path and callback path strategy options" do
        expect(strategy.options.keys).to contain_exactly(:request_path, :callback_path)
      end
    end

    context "when the identity_provider_options_generator raises an exception" do
      let(:exception) { StandardError.new('test exception') }
      let(:failure_result) { double }

      let(:provider_options_generator) do
        Proc.new { raise exception }
      end

      before do
        allow(strategy).to receive(:fail!).and_return(failure_result)
      end

      it "throws a warden symbol" do
        expect { handler.setup(env) }.to throw_symbol(:warden, failure_result)
      end

      it "calls Strategy#fail! with the appropriate arguments" do
        catch(:warden) { handler.setup(env) }
        expect(strategy).to have_received(:fail!).with(:invalid_identity_provider, exception)
      end
    end
  end

  describe "#request_path?" do
    context "when the path is a request path" do
      let(:path) { "#{path_prefix}/#{provider_id}" }

      it "returns true" do
        expect(handler.request_path?(env)).to be(true)
      end
    end

    context "when the path is a request path with a trailing segment" do
      let(:path) { "#{path_prefix}/#{provider_id}/foo" }

      it "returns false" do
        expect(handler.request_path?(env)).to be(false)
      end
    end

    context "when the path is a request path with a leading segment" do
      let(:path) { "/foo#{path_prefix}/#{provider_id}" }

      it "returns false" do
        expect(handler.request_path?(env)).to be(false)
      end
    end

    context "when the path is a request path with an invalid provider id" do
      let(:path) { "#{path_prefix}/foobar" }

      it "returns false" do
        expect(handler.request_path?(env)).to be(false)
      end
    end
  end

  describe "#callback_path?" do

    describe "custom callback_path" do
      let(:handler_options) do
        {
          callback_suffix: 'wow'
        }
      end

      context "when the path is a callback path" do
        let(:path) { "#{path_prefix}/#{provider_id}/wow" }

        it "returns true" do
          expect(handler.callback_path?(env)).to be(true)
        end
      end

      context "when the path is a request path" do
        let(:path) { "#{path_prefix}/#{provider_id}" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end

      context "when the path is a callback path with a trailing segment" do
        let(:path) { "#{path_prefix}/#{provider_id}/wow/foo" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end

      context "when the path is a callback path with a leading segment" do
        let(:path) { "/foo#{path_prefix}/#{provider_id}/wow" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end

      context "when the path is a callback path with an invalid provider id" do
        let(:path) { "#{path_prefix}/foobar/wow" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end
    end

    describe "default callback_path" do
      context "when the path is a callback path" do
        let(:path) { "#{path_prefix}/#{provider_id}/callback" }

        it "returns true" do
          expect(handler.callback_path?(env)).to be(true)
        end
      end

      context "when the path is a request path" do
        let(:path) { "#{path_prefix}/#{provider_id}" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end

      context "when the path is a callback path with a trailing segment" do
        let(:path) { "#{path_prefix}/#{provider_id}/callback/foo" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end

      context "when the path is a callback path with a leading segment" do
        let(:path) { "/foo#{path_prefix}/#{provider_id}/callback" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end

      context "when the path is a callback path with an invalid provider id" do
        let(:path) { "#{path_prefix}/foobar/callback" }

        it "returns false" do
          expect(handler.callback_path?(env)).to be(false)
        end
      end
    end
  end
end
