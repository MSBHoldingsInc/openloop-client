# frozen_string_literal: true

RSpec.describe "GraphQL Types" do
  describe OpenLoop::Client::GraphQL::Types::PatientType do
    it "has expected fields" do
      fields = described_class.fields.keys
      expect(fields).to include("id", "firstName", "lastName", "name", "email", "phoneNumber")
      expect(fields).to include("dob", "gender", "height", "weight", "age")
      expect(fields).to include("timezone", "dietitianId", "location")
    end
  end

  describe OpenLoop::Client::GraphQL::Types::LocationType do
    it "has expected fields" do
      fields = described_class.fields.keys
      expect(fields).to include("line1", "line2", "city", "state", "zip", "country")
    end
  end

  describe OpenLoop::Client::GraphQL::Types::AppointmentType do
    it "has expected fields" do
      fields = described_class.fields.keys
      expect(fields).to include("id", "date", "contactType", "length", "location")
      expect(fields).to include("providerName", "appointmentTypeName", "appointmentTypeId")
    end

    describe "custom resolvers" do
      let(:type_instance) { described_class.new(appointment_data, nil) }
      let(:appointment_data) do
        {
          "id" => "123",
          "provider" => { "full_name" => "Dr. Smith" },
          "appointment_type" => { "name" => "TRT Initial", "id" => "456" }
        }
      end

      it "resolves provider_name from nested data" do
        expect(type_instance.provider_name).to eq("Dr. Smith")
      end

      it "resolves appointment_type_name from nested data" do
        expect(type_instance.appointment_type_name).to eq("TRT Initial")
      end

      it "resolves appointment_type_id from nested data" do
        expect(type_instance.appointment_type_id).to eq("456")
      end
    end
  end

  describe OpenLoop::Client::GraphQL::Types::DocumentType do
    it "has expected fields" do
      fields = described_class.fields.keys
      expect(fields).to include("id", "ownerId", "success")
    end

    describe "custom resolvers" do
      let(:type_instance) { described_class.new(document_data, nil) }

      context "when document exists" do
        let(:document_data) do
          { "document" => { "id" => "doc-123", "owner" => { "id" => "user-456" } } }
        end

        it "resolves owner_id from nested data" do
          expect(type_instance.owner_id).to eq("user-456")
        end

        it "returns true for success" do
          expect(type_instance.success).to eq(true)
        end
      end

      context "when document is nil" do
        let(:document_data) { { "document" => nil } }

        it "returns nil for owner_id" do
          expect(type_instance.owner_id).to be_nil
        end

        it "returns false for success" do
          expect(type_instance.success).to eq(false)
        end
      end
    end
  end

  describe OpenLoop::Client::GraphQL::Types::FormResponseType do
    it "has expected fields" do
      fields = described_class.fields.keys
      expect(fields).to include("success", "message", "data")
    end
  end
end
