# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        # GraphQL type representing a form submission response.
        #
        # This type is returned from form creation mutations (like createTrtForm)
        # and provides status, message, and any returned data.
        #
        # @example Create a TRT form
        #   mutation {
        #     createTrtForm(
        #       patientId: "123"
        #       formReferenceId: 2471727
        #       formData: { modality: "sync_visit" }
        #     ) {
        #       response {
        #         success
        #         message
        #         data
        #       }
        #     }
        #   }
        class FormResponseType < BaseObject
          # @!attribute [r] success
          #   @return [Boolean] Whether the form submission was successful
          field :success, Boolean, null: false

          # @!attribute [r] message
          #   @return [String, nil] Status message or error description
          field :message, String, null: true

          # @!attribute [r] data
          #   @return [Hash, nil] Additional response data as JSON
          field :data, ::GraphQL::Types::JSON, null: true
        end
      end
    end
  end
end
