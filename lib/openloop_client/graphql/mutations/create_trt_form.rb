# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        class CreateTrtForm < BaseMutation
          argument :patient_id, ID, required: true
          argument :form_reference_id, Integer, required: true
          argument :form_data, ::GraphQL::Types::JSON, required: true

          field :response, Types::FormResponseType, null: true
          field :errors, [String], null: true

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
