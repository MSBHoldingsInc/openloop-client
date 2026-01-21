# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        # Mutation for creating a TRT (Testosterone Replacement Therapy) intake form.
        #
        # @example GraphQL mutation
        #   mutation {
        #     createTrtForm(
        #       patientId: "123456"
        #       formReferenceId: 2471727
        #       formData: {
        #         modality: "sync_visit"
        #         service_type: "macro_trt"
        #       }
        #     ) {
        #       response {
        #         success
        #         message
        #         data
        #       }
        #       errors
        #     }
        #   }
        class CreateTrtForm < BaseMutation
          # @!method patient_id
          #   @return [ID] Patient ID (required)
          argument :patient_id, ID, required: true

          # @!method form_reference_id
          #   @return [Integer] Form reference ID (required)
          argument :form_reference_id, Integer, required: true

          # @!method form_data
          #   @return [Hash] Form data as JSON (required)
          argument :form_data, ::GraphQL::Types::JSON, required: true

          # @return [Types::FormResponseType, nil] Form submission response
          field :response, Types::FormResponseType, null: true

          # @return [Array<String>] Error messages if any
          field :errors, [String], null: true

          # Resolves the mutation by creating a TRT form via OpenLoop API.
          #
          # @param patient_id [String] the patient ID
          # @param form_reference_id [Integer] the form reference ID
          # @param form_data [Hash] additional form data
          # @return [Hash] hash with :response and :errors keys
          def resolve(patient_id:, form_reference_id:, form_data:)
            data = form_data.merge(
              patient_id: patient_id,
              formReferenceId: form_reference_id
            )

            response = openloop_client.create_trt_form(data)

            {
              response: {
                success: true,
                message: "Form created successfully",
                data: response
              },
              errors: []
            }
          rescue API::BaseClient::APIError => e
            {
              response: {
                success: false,
                message: e.message,
                data: nil
              },
              errors: [e.message]
            }
          end
        end
      end
    end
  end
end
