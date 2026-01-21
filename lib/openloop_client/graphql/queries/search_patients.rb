# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Queries
        # Query resolver for searching patients by keyword.
        #
        # @example GraphQL query
        #   query {
        #     searchPatients(keywords: "john") {
        #       id
        #       name
        #       email
        #     }
        #   }
        class SearchPatients < BaseQuery
          type [Types::PatientType], null: false

          # @!method keywords
          #   @return [String] Search keywords (name, email, etc.)
          argument :keywords, String, required: true

          # Resolves the search query by searching Healthie API.
          #
          # @param keywords [String] search terms
          # @return [Array<Hash>] array of matching patient data hashes
          # @raise [GraphQL::ExecutionError] if the API request fails
          def resolve(keywords:)
            response = healthie_client.search_patients(keywords)
            response.dig("data", "users") || []
          rescue API::BaseClient::APIError => e
            raise ::GraphQL::ExecutionError, e.message
          end
        end
      end
    end
  end
end
