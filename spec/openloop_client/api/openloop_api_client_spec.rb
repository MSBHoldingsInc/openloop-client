# frozen_string_literal: true

RSpec.describe OpenLoop::Client::API::OpenloopApiClient do
  subject(:client) { described_class.new }

  let(:questionnaire_url) { "https://api.questionnaire.solutions-staging.openloophealth.com" }

  describe "#initialize" do
    it "reads configuration" do
      expect(client.instance_variable_get(:@config)).to eq(OpenLoop::Client.configuration)
    end
  end

  describe "#create_trt_form" do
    let(:form_data) do
      {
        patient_id: "123456",
        formReferenceId: 2156890,
        modality: "sync_visit",
        service_type: "macro_trt"
      }
    end

    before do
      stub_request(:post, "#{questionnaire_url}/create-form")
        .to_return(status: 200, body: '{"success": true, "formId": "form-123"}')
    end

    it "posts form data to the questionnaire endpoint" do
      result = client.create_trt_form(form_data)
      expect(result["success"]).to eq(true)
      expect(result["formId"]).to eq("form-123")
    end

    it "sends data in the correct format" do
      client.create_trt_form(form_data)

      expect(WebMock).to have_requested(:post, "#{questionnaire_url}/create-form")
        .with(body: hash_including("data" => hash_including("patient_id" => "123456")))
    end

    it "raises APIError on failure" do
      stub_request(:post, "#{questionnaire_url}/create-form")
        .to_return(status: 400, body: "Invalid form data")

      expect { client.create_trt_form(form_data) }
        .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Bad Request/)
    end
  end

  describe "#booking_widget_url" do
    it "generates URL for TRT initial visit by default" do
      url = client.booking_widget_url

      expect(url).to include("appointmentTypeId=349681")
      expect(url).to include("providerId=3483153")
      expect(url).to start_with("https://express.care-staging.openloophealth.com/book-appointment")
    end

    it "generates URL for TRT refill visit" do
      url = client.booking_widget_url(therapy_type: "trt", visit_type: "refill")

      expect(url).to include("appointmentTypeId=349682")
    end

    it "generates URL for enclomiphene initial visit" do
      url = client.booking_widget_url(therapy_type: "enclomiphene", visit_type: "initial")

      expect(url).to include("appointmentTypeId=349683")
    end

    it "generates URL for enclomiphene refill visit" do
      url = client.booking_widget_url(therapy_type: "enclomiphene", visit_type: "refill")

      expect(url).to include("appointmentTypeId=349684")
    end

    it "includes additional parameters in the URL" do
      url = client.booking_widget_url(
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        state: "CA",
        zip: "90001"
      )

      expect(url).to include("firstName=John")
      expect(url).to include("lastName=Doe")
      expect(url).to include("email=john%40example.com")
      expect(url).to include("state=CA")
      expect(url).to include("zip=90001")
    end

    it "raises ArgumentError for invalid therapy_type" do
      expect { client.booking_widget_url(therapy_type: "invalid") }
        .to raise_error(ArgumentError, /therapy_type must be one of/)
    end

    it "raises ArgumentError for invalid visit_type" do
      expect { client.booking_widget_url(visit_type: "invalid") }
        .to raise_error(ArgumentError, /visit_type must be one of/)
    end

    context "in production environment" do
      before do
        OpenLoop::Client.configure do |config|
          config.environment = :production
          config.openloop_api_key = "prod-key"
        end
      end

      it "uses production appointment type IDs" do
        url = client.booking_widget_url

        expect(url).to include("appointmentTypeId=472535")
        expect(url).to include("providerId=9584181")
        expect(url).to start_with("https://express.patientcare.openloophealth.com/book-appointment")
      end
    end
  end

  describe "#get_lab_facilities" do
    let(:facilities_url) { "https://api.integrations.clinic.openloophealth.com/labs/facilities" }
    let(:response_body) do
      {
        "facilities" => [
          { "id" => "1", "name" => "Lab Corp", "address" => "123 Main St" },
          { "id" => "2", "name" => "Quest Diagnostics", "address" => "456 Oak Ave" }
        ]
      }
    end

    before do
      stub_request(:get, /#{Regexp.escape(facilities_url)}/)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "returns lab facilities near a zip code" do
      result = client.get_lab_facilities(zip_code: "90210")

      expect(result["facilities"].length).to eq(2)
    end

    it "includes query parameters in the request" do
      client.get_lab_facilities(zip_code: "90210", radius: 25)

      expect(WebMock).to have_requested(:get, facilities_url)
        .with(query: hash_including("zip_code" => "90210", "radius" => "25"))
    end

    it "uses default radius of 50 miles" do
      client.get_lab_facilities(zip_code: "90210")

      expect(WebMock).to have_requested(:get, facilities_url)
        .with(query: hash_including("radius" => "50"))
    end

    it "includes include_psc_details by default" do
      client.get_lab_facilities(zip_code: "90210")

      expect(WebMock).to have_requested(:get, facilities_url)
        .with(query: hash_including("include_psc_details" => "true"))
    end

    it "raises APIError on failure" do
      stub_request(:get, /#{Regexp.escape(facilities_url)}/)
        .to_return(status: 500, body: "Server error")

      expect { client.get_lab_facilities(zip_code: "90210") }
        .to raise_error(OpenLoop::Client::API::BaseClient::APIError, /Server Error/)
    end
  end
end
