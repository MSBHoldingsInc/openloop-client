# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        class AppointmentType < BaseObject
          field :id, ID, null: false
          field :date, String, null: true
          field :contact_type, String, null: true
          field :created_at, String, null: true
          field :length, Integer, null: true
          field :location, String, null: true
          field :provider_name, String, null: true
          field :appointment_type_name, String, null: true
          field :appointment_type_id, String, null: true

          def provider_name
            object.dig("provider", "full_name")
          end

          def appointment_type_name
            object.dig("appointment_type", "name")
          end

          def appointment_type_id
            object.dig("appointment_type", "id")
          end
        end
      end
    end
  end
end
