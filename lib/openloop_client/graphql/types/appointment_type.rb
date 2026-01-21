# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Types
        # GraphQL type representing an appointment from the Healthie API.
        #
        # This type maps appointment data to GraphQL fields, including
        # flattened provider and appointment type information for
        # convenience.
        #
        # @example Query patient appointments
        #   query {
        #     patientAppointments(userId: "123") {
        #       id
        #       date
        #       providerName
        #       appointmentTypeName
        #     }
        #   }
        class AppointmentType < BaseObject
          # @!attribute [r] id
          #   @return [ID] Unique appointment identifier
          field :id, ID, null: false

          # @!attribute [r] date
          #   @return [String, nil] Appointment date/time
          field :date, String, null: true

          # @!attribute [r] contact_type
          #   @return [String, nil] Type of contact (video, phone, etc.)
          field :contact_type, String, null: true

          # @!attribute [r] created_at
          #   @return [String, nil] Record creation timestamp
          field :created_at, String, null: true

          # @!attribute [r] length
          #   @return [Integer, nil] Appointment duration in minutes
          field :length, Integer, null: true

          # @!attribute [r] location
          #   @return [String, nil] Appointment location
          field :location, String, null: true

          # @!attribute [r] provider_name
          #   @return [String, nil] Provider's full name
          field :provider_name, String, null: true

          # @!attribute [r] appointment_type_name
          #   @return [String, nil] Name of the appointment type
          field :appointment_type_name, String, null: true

          # @!attribute [r] appointment_type_id
          #   @return [String, nil] Appointment type ID
          field :appointment_type_id, String, null: true

          # Extracts provider name from nested object.
          # @api private
          # @return [String, nil] the provider's full name
          def provider_name
            object.dig("provider", "full_name")
          end

          # Extracts appointment type name from nested object.
          # @api private
          # @return [String, nil] the appointment type name
          def appointment_type_name
            object.dig("appointment_type", "name")
          end

          # Extracts appointment type ID from nested object.
          # @api private
          # @return [String, nil] the appointment type ID
          def appointment_type_id
            object.dig("appointment_type", "id")
          end
        end
      end
    end
  end
end
