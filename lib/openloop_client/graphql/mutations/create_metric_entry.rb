# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        class CreateMetricEntry < BaseMutation
          argument :category, String, required: true
          argument :type, String, required: true
          argument :metric_stat, String, required: true
          argument :user_id, ID, required: true
          argument :created_at, String, required: false

          field :success, Boolean, null: false
          field :entry_id, ID, null: true
          field :errors, [String], null: true

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
