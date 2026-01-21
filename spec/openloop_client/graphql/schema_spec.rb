# frozen_string_literal: true

RSpec.describe OpenLoop::Client::GraphQL::Schema do
  describe "schema structure" do
    it "has a query type" do
      expect(described_class.query).not_to be_nil
    end

    it "has a mutation type" do
      expect(described_class.mutation).not_to be_nil
    end
  end

  describe "query fields" do
    let(:query_type) { described_class.query }

    it "has patient field" do
      expect(query_type.fields.keys).to include("patient")
    end

    it "has searchPatients field" do
      expect(query_type.fields.keys).to include("searchPatients")
    end

    it "has patientAppointments field" do
      expect(query_type.fields.keys).to include("patientAppointments")
    end
  end

  describe "mutation fields" do
    let(:mutation_type) { described_class.mutation }

    it "has createPatient field" do
      expect(mutation_type.fields.keys).to include("createPatient")
    end

    it "has updatePatient field" do
      expect(mutation_type.fields.keys).to include("updatePatient")
    end

    it "has uploadDocument field" do
      expect(mutation_type.fields.keys).to include("uploadDocument")
    end

    it "has createMetricEntry field" do
      expect(mutation_type.fields.keys).to include("createMetricEntry")
    end

    it "has createInvoice field" do
      expect(mutation_type.fields.keys).to include("createInvoice")
    end

    it "has createTrtForm field" do
      expect(mutation_type.fields.keys).to include("createTrtForm")
    end
  end
end
