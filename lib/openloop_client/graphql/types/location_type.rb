# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        # GraphQL type representing an address/location.
        #
        # Used for patient addresses and other location data throughout
        # the schema.
        #
        # @example Access location in a patient query
        #   query {
        #     patient(id: "123") {
        #       location {
        #         line1
        #         city
        #         state
        #         zip
        #       }
        #     }
        #   }
        class LocationType < BaseObject
          # @!attribute [r] line1
          #   @return [String, nil] Street address line 1
          field :line1, String, null: true

          # @!attribute [r] line2
          #   @return [String, nil] Street address line 2 (apt, suite, etc.)
          field :line2, String, null: true

          # @!attribute [r] city
          #   @return [String, nil] City name
          field :city, String, null: true

          # @!attribute [r] state
          #   @return [String, nil] State/province code
          field :state, String, null: true

          # @!attribute [r] zip
          #   @return [String, nil] ZIP/postal code
          field :zip, String, null: true

          # @!attribute [r] country
          #   @return [String, nil] Country code
          field :country, String, null: true
        end
      end
    end
  end
end
