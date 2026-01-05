# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        class UploadDocument < BaseMutation
          argument :file_string, String, required: true
          argument :display_name, String, required: true
          argument :rel_user_id, ID, required: true

          field :document, Types::DocumentType, null: true
          field :errors, [String], null: true

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
