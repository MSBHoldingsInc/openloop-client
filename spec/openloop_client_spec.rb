# frozen_string_literal: true

RSpec.describe OpenLoop::Client do
  describe "VERSION" do
    it "has a version number" do
      expect(OpenLoop::Client::VERSION).not_to be_nil
      expect(OpenLoop::Client::VERSION).to match(/\d+\.\d+\.\d+/)
    end
  end

  describe ".configure" do
    it "yields a configuration instance" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(OpenLoop::Client::Configuration)
    end

    it "sets configuration values" do
      described_class.configure do |config|
        config.openloop_api_key = "new-test-key"
        config.environment = :production
      end

      expect(described_class.configuration.openloop_api_key).to eq("new-test-key")
      expect(described_class.configuration.environment).to eq(:production)
    end

    it "returns the configuration" do
      result = described_class.configure { |c| c.environment = :staging }
      expect(result).to be_a(OpenLoop::Client::Configuration)
    end
  end

  describe ".reset_configuration" do
    before do
      described_class.configure do |config|
        config.openloop_api_key = "custom-key"
        config.environment = :production
      end
    end

    it "resets configuration to defaults" do
      described_class.reset_configuration

      expect(described_class.configuration.openloop_api_key).to be_nil
      expect(described_class.configuration.environment).to eq(:staging)
    end
  end

  describe ".configuration" do
    it "returns the current configuration" do
      expect(described_class.configuration).to be_a(OpenLoop::Client::Configuration)
    end
  end

  describe "Error" do
    it "is a StandardError subclass" do
      expect(OpenLoop::Client::Error.superclass).to eq(StandardError)
    end

    it "can be raised with a message" do
      expect { raise OpenLoop::Client::Error, "test error" }
        .to raise_error(OpenLoop::Client::Error, "test error")
    end
  end
end
