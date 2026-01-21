# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        # Mutation for updating an existing patient in Healthie.
        #
        # @example GraphQL mutation
        #   mutation {
        #     updatePatient(
        #       id: "123456"
        #       dob: "01/15/1990"
        #       gender: "Male"
        #       location: { city: "Austin", state: "TX" }
        #     ) {
        #       patient {
        #         id
        #         dob
        #         location { city state }
        #       }
        #       errors
        #     }
        #   }
        class UpdatePatient < BaseMutation
          # @!method id
          #   @return [ID] Patient ID to update (required)
          argument :id, ID, required: true

          # @!method dob
          #   @return [String] Date of birth (MM/DD/YYYY format)
          argument :dob, String, required: false

          # @!method gender
          #   @return [String] Patient's gender
          argument :gender, String, required: false

          # @!method height
          #   @return [String] Height in inches
          argument :height, String, required: false

          # @!method additional_record_identifier
          #   @return [String] External record identifier
          argument :additional_record_identifier, String, required: false

          # @!method location
          #   @return [Hash] Location/address data as JSON
          argument :location, ::GraphQL::Types::JSON, required: false

          # @return [Types::PatientType, nil] Updated patient data
          field :patient, Types::PatientType, null: true

          # @return [Array<String>] Error messages if any
          field :errors, [String], null: true

          # Resolves the mutation by updating a patient via Healthie API.
          #
          # @param args [Hash] mutation arguments
          # @return [Hash] hash with :patient and :errors keys
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
