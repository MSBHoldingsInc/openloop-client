# frozen_string_literal: true

RSpec.describe "GraphQL Mutations" do
  let(:healthie_url) { "https://staging-api.gethealthie.com/graphql" }
  let(:questionnaire_url) { "https://api.questionnaire.solutions-staging.openloophealth.com" }

  describe "createPatient mutation" do
    let(:mutation) do
      <<~GRAPHQL
        mutation($firstName: String!, $lastName: String!, $email: String!, $dietitianId: String!) {
          createPatient(firstName: $firstName, lastName: $lastName, email: $email, dietitianId: $dietitianId) {
            patient {
              id
              firstName
              lastName
              email
            }
            errors
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        dietitianId: "789"
      }
    end

    let(:response_body) { MockResponses.healthie_create_patient_response }

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates a patient successfully" do
      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["createPatient"]["patient"]["id"]).to eq("123456")
      expect(result["data"]["createPatient"]["errors"]).to eq([])
    end

    it "returns errors on validation failure" do
      error_response = MockResponses.healthie_error_response(field: "email", message: "is already taken")
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: error_response.to_json)

      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["createPatient"]["patient"]).to be_nil
      expect(result["data"]["createPatient"]["errors"]).to include("email: is already taken")
    end

    it "handles API errors gracefully" do
      stub_request(:post, healthie_url)
        .to_return(status: 500, body: "Internal Server Error")

      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["createPatient"]["patient"]).to be_nil
      expect(result["data"]["createPatient"]["errors"].first).to include("Server Error")
    end
  end

  describe "updatePatient mutation" do
    let(:mutation) do
      <<~GRAPHQL
        mutation($id: ID!, $dob: String, $gender: String) {
          updatePatient(id: $id, dob: $dob, gender: $gender) {
            patient {
              id
              dob
              gender
            }
            errors
          }
        }
      GRAPHQL
    end

    let(:variables) do
      { id: "123456", dob: "01/15/1990", gender: "Male" }
    end

    let(:response_body) do
      {
        "data" => {
          "updateClient" => {
            "user" => { "id" => "123456", "dob" => "01/15/1990", "gender" => "Male" },
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
      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["updatePatient"]["patient"]["dob"]).to eq("01/15/1990")
      expect(result["data"]["updatePatient"]["errors"]).to eq([])
    end
  end

  describe "uploadDocument mutation" do
    let(:mutation) do
      <<~GRAPHQL
        mutation($fileString: String!, $displayName: String!, $relUserId: ID!) {
          uploadDocument(fileString: $fileString, displayName: $displayName, relUserId: $relUserId) {
            document {
              id
              ownerId
              success
            }
            errors
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        fileString: "data:image/jpeg;base64,abc123",
        displayName: "Lab Results",
        relUserId: "123456"
      }
    end

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

    it "uploads a document successfully" do
      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["uploadDocument"]["document"]["ownerId"]).to eq("123456")
      expect(result["data"]["uploadDocument"]["document"]["success"]).to eq(true)
      expect(result["data"]["uploadDocument"]["errors"]).to eq([])
    end
  end

  describe "createMetricEntry mutation" do
    let(:mutation) do
      <<~GRAPHQL
        mutation($category: String!, $type: String!, $metricStat: String!, $userId: ID!) {
          createMetricEntry(category: $category, type: $type, metricStat: $metricStat, userId: $userId) {
            success
            entryId
            errors
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        category: "Weight",
        type: "MetricEntry",
        metricStat: "180",
        userId: "123456"
      }
    end

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

    it "creates a metric entry successfully" do
      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["createMetricEntry"]["success"]).to eq(true)
      expect(result["data"]["createMetricEntry"]["entryId"]).to eq("entry-123")
      expect(result["data"]["createMetricEntry"]["errors"]).to eq([])
    end
  end

  describe "createInvoice mutation" do
    let(:mutation) do
      <<~GRAPHQL
        mutation($recipientId: ID!, $price: String!, $status: String) {
          createInvoice(recipientId: $recipientId, price: $price, status: $status) {
            success
            invoiceId
            errors
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        recipientId: "123456",
        price: "299",
        status: "Paid"
      }
    end

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

    it "creates an invoice successfully" do
      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["createInvoice"]["success"]).to eq(true)
      expect(result["data"]["createInvoice"]["invoiceId"]).to eq("inv-123")
      expect(result["data"]["createInvoice"]["errors"]).to eq([])
    end
  end

  describe "createTrtForm mutation" do
    let(:mutation) do
      <<~GRAPHQL
        mutation($patientId: ID!, $formReferenceId: Int!, $formData: JSON!) {
          createTrtForm(patientId: $patientId, formReferenceId: $formReferenceId, formData: $formData) {
            response {
              success
              message
            }
            errors
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        patientId: "123456",
        formReferenceId: 2156890,
        formData: { modality: "sync_visit", service_type: "macro_trt" }
      }
    end

    before do
      stub_request(:post, "#{questionnaire_url}/create-form")
        .to_return(status: 200, body: '{"success": true, "formId": "form-123"}')
    end

    it "creates a TRT form successfully" do
      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["createTrtForm"]["response"]["success"]).to eq(true)
      expect(result["data"]["createTrtForm"]["response"]["message"]).to eq("Form created successfully")
      expect(result["data"]["createTrtForm"]["errors"]).to eq([])
    end

    it "handles API errors gracefully" do
      stub_request(:post, "#{questionnaire_url}/create-form")
        .to_return(status: 400, body: "Invalid form data")

      result = OpenLoop::Client::GraphQL::Schema.execute(mutation, variables: variables)

      expect(result["data"]["createTrtForm"]["response"]["success"]).to eq(false)
      expect(result["data"]["createTrtForm"]["errors"].first).to include("Bad Request")
    end
  end
end
