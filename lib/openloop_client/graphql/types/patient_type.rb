# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        # GraphQL type representing a patient/user from the Healthie API.
        #
        # This type maps patient data returned from Healthie to GraphQL fields.
        # It includes personal information, contact details, physical attributes,
        # and associated location data.
        #
        # @example Query a patient
        #   query {
        #     patient(id: "123456") {
        #       id
        #       name
        #       email
        #       location {
        #         city
        #         state
        #       }
        #     }
        #   }
        class PatientType < BaseObject
          # @!attribute [r] id
          #   @return [ID] Unique patient identifier
          field :id, ID, null: false

          # @!attribute [r] first_name
          #   @return [String, nil] Patient's first name
          field :first_name, String, null: true

          # @!attribute [r] last_name
          #   @return [String, nil] Patient's last name
          field :last_name, String, null: true

          # @!attribute [r] name
          #   @return [String, nil] Patient's full name
          field :name, String, null: true

          # @!attribute [r] email
          #   @return [String, nil] Patient's email address
          field :email, String, null: true

          # @!attribute [r] phone_number
          #   @return [String, nil] Patient's phone number
          field :phone_number, String, null: true

          # @!attribute [r] dob
          #   @return [String, nil] Date of birth
          field :dob, String, null: true

          # @!attribute [r] gender
          #   @return [String, nil] Patient's gender
          field :gender, String, null: true

          # @!attribute [r] height
          #   @return [String, nil] Height in inches
          field :height, String, null: true

          # @!attribute [r] weight
          #   @return [String, nil] Weight in pounds
          field :weight, String, null: true

          # @!attribute [r] age
          #   @return [Integer, nil] Patient's age
          field :age, Integer, null: true

          # @!attribute [r] timezone
          #   @return [String, nil] Patient's timezone
          field :timezone, String, null: true

          # @!attribute [r] dietitian_id
          #   @return [String, nil] Assigned provider/dietitian ID
          field :dietitian_id, String, null: true

          # @!attribute [r] additional_record_identifier
          #   @return [String, nil] External record identifier
          field :additional_record_identifier, String, null: true

          # @!attribute [r] bmi_percentile
          #   @return [Float, nil] BMI percentile
          field :bmi_percentile, Float, null: true

          # @!attribute [r] next_appt_date
          #   @return [String, nil] Next appointment date
          field :next_appt_date, String, null: true

          # @!attribute [r] created_at
          #   @return [String, nil] Record creation timestamp
          field :created_at, String, null: true

          # @!attribute [r] updated_at
          #   @return [String, nil] Record last update timestamp
          field :updated_at, String, null: true

          # @!attribute [r] location
          #   @return [LocationType, nil] Patient's address
          field :location, LocationType, null: true
        end
      end
    end
  end
end
