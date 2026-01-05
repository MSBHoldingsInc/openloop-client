# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      class Schema < ::GraphQL::Schema
        class QueryType < ::GraphQL::Schema::Object
          field :patient, resolver: Queries::Patient
          field :search_patients, resolver: Queries::SearchPatients
          field :patient_appointments, resolver: Queries::PatientAppointments
        end

        class MutationType < ::GraphQL::Schema::Object
          field :create_patient, mutation: Mutations::CreatePatient
          field :update_patient, mutation: Mutations::UpdatePatient
          field :upload_document, mutation: Mutations::UploadDocument
          field :create_metric_entry, mutation: Mutations::CreateMetricEntry
          field :create_invoice, mutation: Mutations::CreateInvoice
          field :create_trt_form, mutation: Mutations::CreateTrtForm
        end

        query QueryType
        mutation MutationType
      end
    end
  end
end
