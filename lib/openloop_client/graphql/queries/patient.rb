# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Queries
        class Patient < BaseQuery
          type Types::PatientType, null: true

          argument :id, ID, required: true

          def resolve(id:)
            response = healthie_client.get_patient(id)
            response.dig("data", "user")
          rescue API::BaseClient::APIError => e
            raise ::GraphQL::ExecutionError, e.message
          end
        end
      end
    end
  end
end
