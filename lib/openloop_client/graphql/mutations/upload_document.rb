# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        # Mutation for uploading a document for a patient.
        #
        # @example GraphQL mutation
        #   mutation {
        #     uploadDocument(
        #       fileString: "data:image/jpeg;base64,/9j/4AAQ..."
        #       displayName: "Lab Results 2024"
        #       relUserId: "123456"
        #     ) {
        #       document {
        #         id
        #         ownerId
        #         success
        #       }
        #       errors
        #     }
        #   }
        class UploadDocument < BaseMutation
          # @!method file_string
          #   @return [String] Base64-encoded file with MIME type prefix (required)
          argument :file_string, String, required: true

          # @!method display_name
          #   @return [String] Display name for the document (required)
          argument :display_name, String, required: true

          # @!method rel_user_id
          #   @return [ID] Patient ID to associate document with (required)
          argument :rel_user_id, ID, required: true

          # @return [Types::DocumentType, nil] Uploaded document data
          field :document, Types::DocumentType, null: true

          # @return [Array<String>] Error messages if any
          field :errors, [String], null: true

          # Resolves the mutation by uploading a document via Healthie API.
          #
          # @param args [Hash] mutation arguments
          # @return [Hash] hash with :document and :errors keys
          def resolve(**args)
            response = healthie_client.upload_document(args)

            if response.dig("data", "createDocument", "document")
              { document: response["data"]["createDocument"], errors: [] }
            else
              messages = response.dig("data", "createDocument", "messages") || []
              { document: nil, errors: messages.map { |m| "#{m['field']}: #{m['message']}" } }
            end
          rescue API::BaseClient::APIError => e
            { document: nil, errors: [e.message] }
          end
        end
      end
    end
  end
end
