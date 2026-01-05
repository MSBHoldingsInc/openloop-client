# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        class LocationType < BaseObject
          field :line1, String, null: true
          field :line2, String, null: true
          field :city, String, null: true
          field :state, String, null: true
          field :zip, String, null: true
          field :country, String, null: true
        end
      end
    end
  end
end
