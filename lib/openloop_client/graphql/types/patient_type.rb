# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        class PatientType < BaseObject
          field :id, ID, null: false
          field :first_name, String, null: true
          field :last_name, String, null: true
          field :name, String, null: true
          field :email, String, null: true
          field :phone_number, String, null: true
          field :dob, String, null: true
          field :gender, String, null: true
          field :height, String, null: true
          field :weight, String, null: true
          field :age, Integer, null: true
          field :timezone, String, null: true
          field :dietitian_id, String, null: true
          field :additional_record_identifier, String, null: true
          field :bmi_percentile, Float, null: true
          field :next_appt_date, String, null: true
          field :created_at, String, null: true
          field :updated_at, String, null: true
          field :location, LocationType, null: true
        end
      end
    end
  end
end
