# frozen_string_literal: true

RSpec.describe OpenLoop::Client::API::JunctionApiClient do
  subject(:client) { described_class.new }

  let(:vital_url) { "https://api.sandbox.tryvital.io/v3" }

  describe "#initialize" do
    it "reads configuration" do
      expect(client.instance_variable_get(:@config)).to eq(OpenLoop::Client.configuration)
    end
  end

  describe "#get_lab_results" do
    let(:order_id) { "550e8400-e29b-41d4-a716-446655440000" }
    let(:response_body) { MockResponses.vital_lab_results_response }

    before do
      stub_request(:get, "#{vital_url}/order/#{order_id}/result")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns lab results" do
      result = client.get_lab_results(order_id: order_id)

      expect(result["metadata"]["patient"]).to eq("John Doe")
      expect(result["results"].first["name"]).to eq("Testosterone, Total")
    end

    it "includes the vital API key header" do
      client.get_lab_results(order_id: order_id)

      expect(WebMock).to have_requested(:get, "#{vital_url}/order/#{order_id}/result")
        .with(headers: { "x-vital-api-key" => "test-vital-key" })
    end

    it "raises APIError on 404" do
      stub_request(:get, "#{vital_url}/order/#{order_id}/result")
        .to_return(status: 404, body: "Order not found")

      expect { client.get_lab_results(order_id: order_id) }
        .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Not Found/)
    end

    it "raises APIError on 401" do
      stub_request(:get, "#{vital_url}/order/#{order_id}/result")
        .to_return(status: 401, body: "Invalid API key")

      expect { client.get_lab_results(order_id: order_id) }
        .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Unauthorized/)
    end

    context "in production environment" do
      before do
        OpenLoop::Client.configure do |config|
          config.environment = :production
          config.vital_api_key = "prod-vital-key"
        end
      end

      it "uses production vital URL" do
        stub_request(:get, "https://api.tryvital.io/v3/order/#{order_id}/result")
          .to_return(status: 200, body: response_body.to_json)

        client.get_lab_results(order_id: order_id)

        expect(WebMock).to have_requested(:get, "https://api.tryvital.io/v3/order/#{order_id}/result")
      end
    end
  end
end
