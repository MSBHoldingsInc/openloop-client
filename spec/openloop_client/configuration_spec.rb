# frozen_string_literal: true

RSpec.describe OpenLoop::Client::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.healthie_api_key).to be_nil
      expect(config.healthie_authorization_shard).to be_nil
      expect(config.openloop_api_key).to be_nil
      expect(config.vital_api_key).to be_nil
      expect(config.environment).to eq(:staging)
    end
  end

  describe "attribute accessors" do
    it "allows setting healthie_api_key" do
      config.healthie_api_key = "test-key"
      expect(config.healthie_api_key).to eq("test-key")
    end

    it "allows setting healthie_authorization_shard" do
      config.healthie_authorization_shard = "test-shard"
      expect(config.healthie_authorization_shard).to eq("test-shard")
    end

    it "allows setting openloop_api_key" do
      config.openloop_api_key = "test-openloop-key"
      expect(config.openloop_api_key).to eq("test-openloop-key")
    end

    it "allows setting vital_api_key" do
      config.vital_api_key = "test-vital-key"
      expect(config.vital_api_key).to eq("test-vital-key")
    end

    it "allows setting environment" do
      config.environment = :production
      expect(config.environment).to eq(:production)
    end
  end

  describe "#healthie_url" do
    context "when environment is staging" do
      before { config.environment = :staging }

      it "returns staging URL" do
        expect(config.healthie_url).to eq("https://staging-api.gethealthie.com/graphql")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production URL" do
        expect(config.healthie_url).to eq("https://api.gethealthie.com/graphql")
      end
    end
  end

  describe "#openloop_questionnaire_url" do
    context "when environment is staging" do
      before { config.environment = :staging }

      it "returns staging URL" do
        expect(config.openloop_questionnaire_url).to eq("https://api.questionnaire.solutions-staging.openloophealth.com")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production URL" do
        expect(config.openloop_questionnaire_url).to eq("https://api.questionnaire.solutions.openloophealth.com")
      end
    end
  end

  describe "#openloop_booking_widget_base_url" do
    context "when environment is staging" do
      before { config.environment = :staging }

      it "returns staging URL" do
        expect(config.openloop_booking_widget_base_url).to eq("https://express.care-staging.openloophealth.com/book-appointment")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production URL" do
        expect(config.openloop_booking_widget_base_url).to eq("https://express.patientcare.openloophealth.com/book-appointment")
      end
    end
  end

  describe "#vital_api_url" do
    context "when environment is staging" do
      before { config.environment = :staging }

      it "returns sandbox URL" do
        expect(config.vital_api_url).to eq("https://api.sandbox.tryvital.io/v3")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production URL" do
        expect(config.vital_api_url).to eq("https://api.tryvital.io/v3")
      end
    end
  end

  describe "#org_id" do
    it "returns staging org ID by default" do
      expect(config.org_id).to eq("167021")
    end

    it "returns production org ID when environment is production" do
      config.environment = :production
      expect(config.org_id).to eq("93721")
    end
  end

  describe "#provider_id" do
    it "returns staging provider ID by default" do
      expect(config.provider_id).to eq("3483153")
    end

    it "returns production provider ID when environment is production" do
      config.environment = :production
      expect(config.provider_id).to eq("9584181")
    end
  end

  describe "#form_ids" do
    context "when environment is staging" do
      it "returns staging form IDs" do
        expect(config.form_ids[:trt_initial]).to eq("2156890")
        expect(config.form_ids[:trt_refill]).to eq("2156891")
        expect(config.form_ids[:labs_upload_completed]).to eq("2190741")
        expect(config.form_ids[:trt_encounter_note]).to eq("2190742")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production form IDs" do
        expect(config.form_ids[:trt_initial]).to eq("2471727")
        expect(config.form_ids[:trt_refill]).to eq("2471728")
        expect(config.form_ids[:labs_upload_completed]).to eq("2638349")
        expect(config.form_ids[:trt_encounter_note]).to eq("2841159")
      end
    end
  end

  describe "#appointment_type_ids" do
    context "when environment is staging" do
      it "returns staging appointment type IDs" do
        expect(config.appointment_type_ids[:trt_initial]).to eq("349681")
        expect(config.appointment_type_ids[:trt_refill]).to eq("349682")
        expect(config.appointment_type_ids[:enclomiphene_initial]).to eq("349683")
        expect(config.appointment_type_ids[:enclomiphene_refill]).to eq("349684")
      end
    end

    context "when environment is production" do
      before { config.environment = :production }

      it "returns production appointment type IDs" do
        expect(config.appointment_type_ids[:trt_initial]).to eq("472535")
        expect(config.appointment_type_ids[:trt_refill]).to eq("472536")
        expect(config.appointment_type_ids[:enclomiphene_initial]).to eq("472537")
        expect(config.appointment_type_ids[:enclomiphene_refill]).to eq("472538")
      end
    end
  end

  describe "#booking_widget_url" do
    before { config.environment = :staging }

    it "builds URL for trt_initial appointment type" do
      url = config.booking_widget_url(:trt_initial)
      expect(url).to include("appointmentTypeId=349681")
      expect(url).to include("providerId=3483153")
      expect(url).to start_with("https://express.care-staging.openloophealth.com/book-appointment")
    end

    it "returns nil for unknown appointment type" do
      expect(config.booking_widget_url(:unknown_type)).to be_nil
    end
  end
end
