# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Queries
        class PatientAppointments < BaseQuery
          type [Types::AppointmentType], null: false

          argument :user_id, ID, required: true
          argument :filter, String, required: false

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
