# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        class CreatePatient < BaseMutation
          argument :first_name, String, required: true
          argument :last_name, String, required: true
          argument :email, String, required: true
          argument :phone_number, String, required: false
          argument :dietitian_id, String, required: true
          argument :additional_record_identifier, String, required: false
          argument :user_group_id, String, required: false
          argument :skipped_email, Boolean, required: false
          argument :dont_send_welcome, Boolean, required: false

          field :patient, Types::PatientType, null: true
          field :errors, [String], null: true

          def resolve(**args)
            response = healthie_client.create_patient(args)
            user_data = response.dig("data", "createClient", "user")
            messages = response.dig("data", "createClient", "messages")

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
