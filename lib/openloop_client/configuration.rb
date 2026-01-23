# frozen_string_literal: true

module OpenLoop
  module Client
    class Configuration
      attr_accessor :healthie_api_key,
                    :healthie_authorization_shard,
                    :openloop_api_key,
                    :vital_api_key,
                    :environment

      def initialize
        @healthie_api_key = nil
        @healthie_authorization_shard = nil
        @openloop_api_key = nil
        @vital_api_key = nil
        @environment = :staging
      end

      def healthie_url
        default_healthie_url
      end

      def openloop_questionnaire_url
        default_questionnaire_url
      end

      def openloop_booking_widget_base_url
        default_booking_widget_base_url
      end

      def org_id
        default_org_id
      end

      def provider_id
        default_provider_id
      end

      def form_ids
        default_form_ids
      end

      def appointment_type_ids
        default_appointment_type_ids
      end

      def vital_api_url
        default_vital_api_url
      end

      # Helper method to build booking widget URL
      def booking_widget_url(appointment_type_key)
        appointment_type_id = appointment_type_ids[appointment_type_key]
        return nil unless appointment_type_id

        "#{openloop_booking_widget_base_url}?appointmentTypeId=#{appointment_type_id}&providerId=#{provider_id}"
      end

      private

      def default_healthie_url
        "https://api.gethealthie.com/graphql"
      end

      def default_questionnaire_url
        "https://api.questionnaire.solutions.openloophealth.com"
      end

      def default_booking_widget_base_url
        "https://express.patientcare.openloophealth.com/book-appointment"
      end

      def default_vital_api_url
        environment == :production ?
          "https://api.tryvital.io/v3" :
          "https://api.sandbox.tryvital.io/v3"
      end

      def default_org_id
        # To be updated once production org IDs are available
        environment == :production ? "93721" : "93721"
      end

      def default_provider_id
        # To be updated once production provider IDs are available
        environment == :production ? "9584181" : "9584181"
      end

      def default_form_ids
        if environment == :production
          # To be updated once production form IDs are available
          {
            trt_initial: "2471727",
            trt_refill: "2471728",
            labs_upload_completed: "2638349",
            trt_encounter_note: "2841159"
          }
        else
          {
            trt_initial: "2471727",
            trt_refill: "2471728",
            labs_upload_completed: "2638349",
            trt_encounter_note: "2841159"
          }
        end
      end

      def default_appointment_type_ids
        # To be updated once production appointment type IDs are available
        if environment == :production
          {
            trt_initial: "472535",
            trt_refill: "472536",
            enclomiphene_initial: "472537",
            enclomiphene_refill: "472538"
          }
        else
          {
            trt_initial: "472535",
            trt_refill: "472536",
            enclomiphene_initial: "472537",
            enclomiphene_refill: "472538"
          }
        end
      end
    end
  end
end
