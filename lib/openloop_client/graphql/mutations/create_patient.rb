# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        # Mutation for creating a new patient in Healthie.
        #
        # @example GraphQL mutation
        #   mutation {
        #     createPatient(
        #       firstName: "John"
        #       lastName: "Doe"
        #       email: "john@example.com"
        #       dietitianId: "123456"
        #     ) {
        #       patient {
        #         id
        #         name
        #       }
        #       errors
        #     }
        #   }
        class CreatePatient < BaseMutation
          # @!method first_name
          #   @return [String] Patient's first name (required)
          argument :first_name, String, required: true

          # @!method last_name
          #   @return [String] Patient's last name (required)
          argument :last_name, String, required: true

          # @!method email
          #   @return [String] Patient's email address (required)
          argument :email, String, required: true

          # @!method phone_number
          #   @return [String] Patient's phone number
          argument :phone_number, String, required: false

          # @!method dietitian_id
          #   @return [String] Provider/dietitian ID to assign (required)
          argument :dietitian_id, String, required: true

          # @!method additional_record_identifier
          #   @return [String] External record identifier
          argument :additional_record_identifier, String, required: false

          # @!method user_group_id
          #   @return [String] User group ID
          argument :user_group_id, String, required: false

          # @!method skipped_email
          #   @return [Boolean] Whether email was skipped
          argument :skipped_email, Boolean, required: false

          # @!method dont_send_welcome
          #   @return [Boolean] Skip sending welcome email
          argument :dont_send_welcome, Boolean, required: false

          # @return [Types::PatientType, nil] Created patient data
          field :patient, Types::PatientType, null: true

          # @return [Array<String>] Error messages if any
          field :errors, [String], null: true

          # Resolves the mutation by creating a patient via Healthie API.
          #
          # @param args [Hash] mutation arguments
          # @return [Hash] hash with :patient and :errors keys
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
