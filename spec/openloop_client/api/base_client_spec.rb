# frozen_string_literal: true

RSpec.describe OpenLoop::Client::API::BaseClient do
  describe OpenLoop::Client::API::BaseClient::APIError do
    describe "#initialize" do
      it "stores the message" do
        error = described_class.new("Test error message")
        expect(error.message).to eq("Test error message")
      end

      it "stores the response object" do
        mock_response = double("Response", code: 400, body: "Bad Request")
        error = described_class.new("Test error", mock_response)

        expect(error.response).to eq(mock_response)
      end

      it "allows nil response" do
        error = described_class.new("Test error")
        expect(error.response).to be_nil
      end
    end

    it "is a StandardError subclass" do
      expect(described_class.superclass).to eq(StandardError)
    end
  end

  # Test the handle_response method indirectly through a subclass
  describe "response handling" do
    let(:test_client_class) do
      Class.new(described_class) do
        def test_handle_response(response)
          handle_response(response)
        end
      end
    end

    let(:client) { test_client_class.new }

    context "with successful response" do
      it "parses JSON for 200 response" do
        response = double("Response", code: 200, body: '{"success": true}')
        result = client.test_handle_response(response)
        expect(result).to eq({ "success" => true })
      end

      it "parses JSON for 201 response" do
        response = double("Response", code: 201, body: '{"created": true}')
        result = client.test_handle_response(response)
        expect(result).to eq({ "created" => true })
      end
    end

    context "with error responses" do
      it "raises APIError for 400 Bad Request" do
        response = double("Response", code: 400, body: "Invalid input")
        expect { client.test_handle_response(response) }
          .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Bad Request/)
      end

      it "raises APIError for 401 Unauthorized" do
        response = double("Response", code: 401, body: "Invalid credentials")
        expect { client.test_handle_response(response) }
          .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Unauthorized/)
      end

      it "raises APIError for 404 Not Found" do
        response = double("Response", code: 404, body: "Resource not found")
        expect { client.test_handle_response(response) }
          .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Not Found/)
      end

      it "raises APIError for 500 Server Error" do
        response = double("Response", code: 500, body: "Internal error")
        expect { client.test_handle_response(response) }
          .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Server Error/)
      end

      it "raises APIError for unexpected status codes" do
        response = double("Response", code: 418, body: "I'm a teapot")
        expect { client.test_handle_response(response) }
          .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Unexpected response code 418/)
      end
    end

    context "with invalid JSON response" do
      it "raises APIError for malformed JSON" do
        response = double("Response", code: 200, body: "not valid json {")
        expect { client.test_handle_response(response) }
          .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Invalid JSON response/)
      end
    end
  end
end
