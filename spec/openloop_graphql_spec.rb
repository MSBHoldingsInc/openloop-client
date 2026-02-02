# frozen_string_literal: true

RSpec.describe OpenLoop::Client do
  it "has a version number" do
    expect(OpenLoop::Client::VERSION).not_to be nil
  end

  it "has a configuration method" do
    expect(OpenLoop::Client).to respond_to(:configure)
  end

  it "has a configuration accessor" do
    expect(OpenLoop::Client).to respond_to(:configuration)
  end
end
