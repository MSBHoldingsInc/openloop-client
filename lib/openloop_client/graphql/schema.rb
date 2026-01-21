# frozen_string_literal: true

module OpenLoop
  module Client
    # GraphQL module containing the schema, types, queries, and mutations.
    #
    # This module provides a GraphQL interface wrapping the underlying REST
    # API clients. It can be used directly or mounted in a Rails application.
    #
    # @example Execute a query directly
    #   query = '{ patient(id: "123") { name email } }'
    #   result = OpenLoop::Client::GraphQL::Schema.execute(query)
    #
    # @see OpenLoop::Client::GraphQL::Schema Main schema class
    # @see OpenLoop::Client::GraphQL::Queries Query resolvers
    # @see OpenLoop::Client::GraphQL::Mutations Mutation resolvers
    module GraphQL
      # Main GraphQL schema for the OpenLoop client.
      #
      # This schema provides queries for retrieving patient and appointment
      # data, and mutations for creating/updating patients, uploading
      # documents, and more.
      #
      # @example Execute a query
      #   result = OpenLoop::Client::GraphQL::Schema.execute(
      #     '{ patient(id: "123") { name email } }'
      #   )
      #
      # @example Execute a mutation
      #   result = OpenLoop::Client::GraphQL::Schema.execute(
      #     'mutation { createPatient(firstName: "John", lastName: "Doe", email: "john@example.com", dietitianId: "456") { patient { id } } }'
      #   )
      class Schema < ::GraphQL::Schema
        # Root query type containing all available queries.
        # @api private
        class QueryType < ::GraphQL::Schema::Object
          field :patient, resolver: Queries::Patient
          field :search_patients, resolver: Queries::SearchPatients
          field :patient_appointments, resolver: Queries::PatientAppointments
        end

        # Root mutation type containing all available mutations.
        # @api private
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
