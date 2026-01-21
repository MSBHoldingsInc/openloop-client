# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        # Mutation for creating a metric entry (e.g., weight) for a patient.
        #
        # @example GraphQL mutation
        #   mutation {
        #     createMetricEntry(
        #       category: "Weight"
        #       type: "MetricEntry"
        #       metricStat: "180"
        #       userId: "123456"
        #       createdAt: "1/15/2024"
        #     ) {
        #       success
        #       entryId
        #       errors
        #     }
        #   }
        class CreateMetricEntry < BaseMutation
          # @!method category
          #   @return [String] Metric category (e.g., "Weight") (required)
          argument :category, String, required: true

          # @!method type
          #   @return [String] Entry type (e.g., "MetricEntry") (required)
          argument :type, String, required: true

          # @!method metric_stat
          #   @return [String] The metric value (required)
          argument :metric_stat, String, required: true

          # @!method user_id
          #   @return [ID] Patient ID (required)
          argument :user_id, ID, required: true

          # @!method created_at
          #   @return [String] Entry date (M/D/YYYY format)
          argument :created_at, String, required: false

          # @return [Boolean] Whether the entry was created successfully
          field :success, Boolean, null: false

          # @return [ID, nil] ID of the created entry
          field :entry_id, ID, null: true

          # @return [Array<String>] Error messages if any
          field :errors, [String], null: true

          # Resolves the mutation by creating a metric entry via Healthie API.
          #
          # @param args [Hash] mutation arguments
          # @return [Hash] hash with :success, :entry_id, and :errors keys
          def resolve(**args)
            response = healthie_client.create_metric_entry(args)
            entry_data = response.dig("data", "createEntry", "entry")
            messages = response.dig("data", "createEntry", "messages")

            if entry_data
              { success: true, entry_id: entry_data["id"], errors: [] }
            else
              { success: false, entry_id: nil, errors: messages&.map { |m| "#{m['field']}: #{m['message']}" } || [] }
            end
          rescue API::BaseClient::APIError => e
            { success: false, entry_id: nil, errors: [e.message] }
          end
        end
      end
    end
  end
end
