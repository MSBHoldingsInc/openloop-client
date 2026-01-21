# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Queries
        # Query resolver for fetching a single patient by ID.
        #
        # @example GraphQL query
        #   query {
        #     patient(id: "123456") {
        #       id
        #       name
        #       email
        #       location {
        #         city
        #         state
        #       }
        #     }
        #   }
        class Patient < BaseQuery
          type Types::PatientType, null: true

          # @!method id
          #   @return [ID] The patient ID to fetch
          argument :id, ID, required: true

          # Resolves the patient query by fetching from Healthie API.
          #
          # @param id [String] the patient ID
          # @return [Hash, nil] patient data hash or nil if not found
          # @raise [GraphQL::ExecutionError] if the API request fails
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
