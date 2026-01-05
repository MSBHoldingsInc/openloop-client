# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        class FormResponseType < BaseObject
          field :success, Boolean, null: false
          field :message, String, null: true
          field :data, ::GraphQL::Types::JSON, null: true
        end
      end
    end
  end
end
