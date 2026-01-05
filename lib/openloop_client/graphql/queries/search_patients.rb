# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Queries
        class SearchPatients < BaseQuery
          type [Types::PatientType], null: false

          argument :keywords, String, required: true

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
