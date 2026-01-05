# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        class UpdatePatient < BaseMutation
          argument :id, ID, required: true
          argument :dob, String, required: false
          argument :gender, String, required: false
          argument :height, String, required: false
          argument :additional_record_identifier, String, required: false
          argument :location, ::GraphQL::Types::JSON, required: false

          field :patient, Types::PatientType, null: true
          field :errors, [String], null: true

          def resolve(**args)
            response = healthie_client.update_patient(args)
            user_data = response.dig("data", "updateClient", "user")
            messages = response.dig("data", "updateClient", "messages")

            if messages&.any?
              { patient: nil, errors: messages.map { |m| "#{m['field']}: #{m['message']}" } }
            else
              { patient: user_data, errors: [] }
            end
          rescue API::BaseClient::APIError => e
            { patient: nil, errors: [e.message] }
          end
        end
      end
    end
  end
end
