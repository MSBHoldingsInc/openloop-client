# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Queries
        # Query resolver for fetching a patient's appointments.
        #
        # @example GraphQL query for all appointments
        #   query {
        #     patientAppointments(userId: "123456") {
        #       id
        #       date
        #       providerName
        #       appointmentTypeName
        #     }
        #   }
        #
        # @example Query with filter
        #   query {
        #     patientAppointments(userId: "123456", filter: "upcoming") {
        #       id
        #       date
        #     }
        #   }
        class PatientAppointments < BaseQuery
          type [Types::AppointmentType], null: false

          # @!method user_id
          #   @return [ID] The patient/user ID
          argument :user_id, ID, required: true

          # @!method filter
          #   @return [String] Appointment filter ("all", "upcoming", "past")
          argument :filter, String, required: false

          # Resolves the query by fetching appointments from Healthie API.
          #
          # @param user_id [String] the patient ID
          # @param filter [String] optional filter for appointment status
          # @return [Array<Hash>] array of appointment data hashes
          # @raise [GraphQL::ExecutionError] if the API request fails
          def resolve(user_id:, filter: "all")
            response = healthie_client.get_patient_appointments(user_id, filter)
            response.dig("data", "appointments") || []
          rescue API::BaseClient::APIError => e
            raise ::GraphQL::ExecutionError, e.message
          end
        end
      end
    end
  end
end
