# frozen_string_literal: true

RSpec.describe "GraphQL Queries" do
  let(:healthie_url) { "https://staging-api.gethealthie.com/graphql" }

  describe "patient query" do
    let(:query) do
      <<~GRAPHQL
        query($id: ID!) {
          patient(id: $id) {
            id
            name
            email
            firstName
            lastName
          }
        }
      GRAPHQL
    end

    let(:response_body) { MockResponses.healthie_patient_response }

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns patient data" do
      result = OpenLoop::Client::GraphQL::Schema.execute(query, variables: { id: "123456" })

      expect(result["data"]["patient"]["id"]).to eq("123456")
      expect(result["data"]["patient"]["name"]).to eq("John Doe")
      expect(result["data"]["patient"]["email"]).to eq("john@example.com")
    end

    it "returns nil for non-existent patient" do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: { "data" => { "user" => nil } }.to_json)

      result = OpenLoop::Client::GraphQL::Schema.execute(query, variables: { id: "nonexistent" })

      expect(result["data"]["patient"]).to be_nil
    end

    it "returns error on API failure" do
      stub_request(:post, healthie_url)
        .to_return(status: 401, body: "Unauthorized")

      result = OpenLoop::Client::GraphQL::Schema.execute(query, variables: { id: "123" })

      expect(result["errors"]).not_to be_empty
      expect(result["errors"].first["message"]).to include("Unauthorized")
    end
  end

  describe "searchPatients query" do
    let(:query) do
      <<~GRAPHQL
        query($keywords: String!) {
          searchPatients(keywords: $keywords) {
            id
            name
            email
          }
        }
      GRAPHQL
    end

    let(:response_body) do
      MockResponses.healthie_search_response(users: [
        { id: "1", first_name: "John", last_name: "Doe", email: "john@example.com" },
        { id: "2", first_name: "Johnny", last_name: "Smith", email: "johnny@example.com" }
      ])
    end

    before do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns matching patients" do
      result = OpenLoop::Client::GraphQL::Schema.execute(query, variables: { keywords: "john" })

      expect(result["data"]["searchPatients"].length).to eq(2)
      expect(result["data"]["searchPatients"].first["name"]).to eq("John Doe")
    end

    it "returns empty array when no matches" do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: { "data" => { "users" => [] } }.to_json)

      result = OpenLoop::Client::GraphQL::Schema.execute(query, variables: { keywords: "xyz123" })

      expect(result["data"]["searchPatients"]).to eq([])
    end
  end

  describe "patientAppointments query" do
    let(:query) do
      <<~GRAPHQL
        query($userId: ID!, $filter: String) {
          patientAppointments(userId: $userId, filter: $filter) {
            id
            date
            providerName
            appointmentTypeName
          }
        }
      GRAPHQL
    end

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

    it "returns patient appointments" do
      result = OpenLoop::Client::GraphQL::Schema.execute(query, variables: { userId: "123456" })

      expect(result["data"]["patientAppointments"].length).to eq(2)
      expect(result["data"]["patientAppointments"].first["id"]).to eq("apt-1")
    end

    it "accepts filter parameter" do
      result = OpenLoop::Client::GraphQL::Schema.execute(
        query,
        variables: { userId: "123456", filter: "upcoming" }
      )

      expect(result["data"]["patientAppointments"]).not_to be_nil
    end

    it "returns empty array when no appointments" do
      stub_request(:post, healthie_url)
        .to_return(status: 200, body: { "data" => { "appointments" => [] } }.to_json)

      result = OpenLoop::Client::GraphQL::Schema.execute(query, variables: { userId: "123456" })

      expect(result["data"]["patientAppointments"]).to eq([])
    end
  end
end
