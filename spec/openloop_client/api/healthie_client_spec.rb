# frozen_string_literal: true

RSpec.describe OpenLoop::Client::API::HealthieClient do
  subject(:client) { described_class.new }

  let(:healthie_url) { "https://staging-api.gethealthie.com/graphql" }

  describe "#initialize" do
    it "reads configuration" do
      expect(client.instance_variable_get(:@config)).to eq(OpenLoop::Client.configuration)
    end
  end

  describe "#execute_query" do
    it "posts to the Healthie GraphQL endpoint" do
      stub_request(:post, healthie_url)
        .with(
          body: hash_including("query" => "{ test }"),
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(status: 200, body: '{"data": {"test": true}}')

      result = client.execute_query("{ test }")
      expect(result).to eq({ "data" => { "test" => true } })
    end

    it "includes variables in the request" do
      stub_request(:post, healthie_url)
        .with(body: hash_including("variables" => { "id" => "123" }))
        .to_return(status: 200, body: '{"data": {}}')

      client.execute_query("query($id: ID) { user(id: $id) { id } }", { id: "123" })

      expect(WebMock).to have_requested(:post, healthie_url)
        .with(body: hash_including("variables" => { "id" => "123" }))
    end

    it "uses Bearer auth when openloop_api_key is set" do
      stub_request(:post, healthie_url)
        .with(headers: { "Authorization" => "Bearer test-api-key" })
        .to_return(status: 200, body: '{"data": {}}')

      client.execute_query("{ test }")

      expect(WebMock).to have_requested(:post, healthie_url)
        .with(headers: { "Authorization" => "Bearer test-api-key" })
    end

    it "includes AuthorizationShard header when set" do
      stub_request(:post, healthie_url)
        .with(headers: { "AuthorizationShard" => "test-shard" })
        .to_return(status: 200, body: '{"data": {}}')

      client.execute_query("{ test }")

      expect(WebMock).to have_requested(:post, healthie_url)
        .with(headers: { "AuthorizationShard" => "test-shard" })
    end

    context "with Basic auth (healthie_api_key)" do
      before do
        OpenLoop::Client.configure do |config|
          config.healthie_api_key = "basic-auth-key"
          config.openloop_api_key = nil
        end
      end

      it "uses Basic auth when only healthie_api_key is set" do
        stub_request(:post, healthie_url)
          .with(headers: { "Authorization" => "Basic basic-auth-key" })
          .to_return(status: 200, body: '{"data": {}}')

        client.execute_query("{ test }")

        expect(WebMock).to have_requested(:post, healthie_url)
          .with(headers: { "Authorization" => "Basic basic-auth-key" })
      end
    end
  end

  describe "#get_patient" do
    let(:response_body) { MockResponses.healthie_patient_response }

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns patient data" do
      result = client.get_patient("123456")
      expect(result.dig("data", "user", "id")).to eq("123456")
      expect(result.dig("data", "user", "first_name")).to eq("John")
    end

    it "raises APIError on failure" do
      stub_request(:post, healthie_url)
        .to_return(status: 401, body: "Unauthorized")

      expect { client.get_patient("123456") }
        .to raise_error(OpenLoop::Client::API::BaseClient::APIError)
    end
  end

  describe "#search_patients" do
    let(:response_body) do
      MockResponses.healthie_search_response(users: [
        { id: "1", first_name: "John", last_name: "Doe" },
        { id: "2", first_name: "Jane", last_name: "Smith" }
      ])
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns matching users" do
      result = client.search_patients("john")
      expect(result.dig("data", "users").length).to eq(2)
    end
  end

  describe "#create_patient" do
    let(:response_body) { MockResponses.healthie_create_patient_response }
    let(:input) do
      {
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        dietitian_id: "789"
      }
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates a patient and returns data" do
      result = client.create_patient(input)
      expect(result.dig("data", "createClient", "user", "id")).to eq("123456")
    end

    it "returns error messages when creation fails" do
      error_response = MockResponses.healthie_error_response(field: "email", message: "already taken")
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: error_response.to_json)

      result = client.create_patient(input)
      messages = result.dig("data", "createClient", "messages")
      expect(messages.first["message"]).to eq("already taken")
    end
  end

  describe "#update_patient" do
    let(:response_body) do
      {
        "data" => {
          "updateClient" => {
            "user" => { "id" => "123", "dob" => "01/15/1990" },
            "messages" => []
          }
        }
      }
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "updates patient data" do
      result = client.update_patient({ id: "123", dob: "01/15/1990" })
      expect(result.dig("data", "updateClient", "user", "dob")).to eq("01/15/1990")
    end
  end

  describe "#upload_document" do
    let(:response_body) do
      {
        "data" => {
          "createDocument" => {
            "document" => { "id" => "doc-123", "owner" => { "id" => "123456" } },
            "messages" => []
          }
        }
      }
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "uploads a document" do
      result = client.upload_document({
        file_string: "data:image/jpeg;base64,abc123",
        display_name: "Test Doc",
        rel_user_id: "123456"
      })
      expect(result.dig("data", "createDocument", "document", "id")).to eq("doc-123")
    end
  end

  describe "#create_metric_entry" do
    let(:response_body) do
      {
        "data" => {
          "createEntry" => {
            "entry" => { "id" => "entry-123", "category" => "Weight", "type" => "MetricEntry" },
            "messages" => []
          }
        }
      }
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates a metric entry" do
      result = client.create_metric_entry({
        category: "Weight",
        type: "MetricEntry",
        metric_stat: "180",
        user_id: "123456"
      })
      expect(result.dig("data", "createEntry", "entry", "id")).to eq("entry-123")
    end
  end

  describe "#create_invoice" do
    let(:response_body) do
      {
        "data" => {
          "createRequestedPayment" => {
            "requestedPayment" => { "id" => "inv-123" },
            "messages" => []
          }
        }
      }
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates an invoice" do
      result = client.create_invoice({
        recipient_id: "123456",
        price: "299"
      })
      expect(result.dig("data", "createRequestedPayment", "requestedPayment", "id")).to eq("inv-123")
    end
  end

  describe "#get_patient_appointments" do
    let(:response_body) do
      MockResponses.healthie_appointments_response(appointments: [
        { id: "apt-1", date: "2024-01-20T10:00:00Z" },
        { id: "apt-2", date: "2024-01-25T14:00:00Z" }
      ])
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns appointments" do
      result = client.get_patient_appointments("123456")
      expect(result.dig("data", "appointments").length).to eq(2)
    end

    it "accepts a filter parameter" do
      result = client.get_patient_appointments("123456", "upcoming")
      expect(result.dig("data", "appointments")).not_to be_nil
    end
  end

  describe "#get_appointment" do
    let(:response_body) { MockResponses.healthie_appointment_response(id: "apt-123") }

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns appointment details" do
      result = client.get_appointment("apt-123")
      expect(result.dig("data", "appointment", "id")).to eq("apt-123")
      expect(result.dig("data", "appointment", "provider", "name")).to eq("Dr. Smith")
    end
  end

  describe "#cancel_appointment" do
    let(:response_body) do
      {
        "data" => {
          "updateAppointment" => {
            "appointment" => { "id" => "apt-123", "pm_status" => "Cancelled" }
          }
        }
      }
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "cancels an appointment" do
      result = client.cancel_appointment("apt-123")
      expect(result.dig("data", "updateAppointment", "appointment", "pm_status")).to eq("Cancelled")
    end
  end
end
