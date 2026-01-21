# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        # GraphQL type representing an uploaded document response.
        #
        # This type is returned from the uploadDocument mutation and
        # indicates whether the upload was successful and provides
        # the document ID and owner information.
        #
        # @example Upload a document
        #   mutation {
        #     uploadDocument(
        #       fileString: "data:image/jpeg;base64,..."
        #       displayName: "Lab Results"
        #       relUserId: "123"
        #     ) {
        #       document {
        #         id
        #         ownerId
        #         success
        #       }
        #     }
        #   }
        class DocumentType < BaseObject
          # @!attribute [r] id
          #   @return [ID] Document identifier
          field :id, ID, null: false

          # @!attribute [r] owner_id
          #   @return [String, nil] ID of the document owner (patient)
          field :owner_id, String, null: true

          # @!attribute [r] success
          #   @return [Boolean] Whether the upload was successful
          field :success, Boolean, null: false

          # Extracts owner ID from nested document object.
          # @api private
          # @return [String, nil] the owner's ID
          def owner_id
            object.dig("document", "owner", "id")
          end

          # Determines if the upload was successful.
          # @api private
          # @return [Boolean] true if document exists in response
          def success
            object["document"].present?
          end
        end
      end
    end
  end
end
