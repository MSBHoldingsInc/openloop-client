# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        class DocumentType < BaseObject
          field :id, ID, null: false
          field :owner_id, String, null: true
          field :success, Boolean, null: false

          def owner_id
            object.dig("document", "owner", "id")
          end

          def success
            object["document"].present?
          end
        end
      end
    end
  end
end
