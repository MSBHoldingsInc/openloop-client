# frozen_string_literal: true

module OpenLoop
  module Client
    class Configuration
      attr_accessor :healthie_api_key,
                    :healthie_url,
                    :healthie_authorization_shard,
                    :openloop_questionnaire_url,
                    :openloop_booking_widget_base_url,
                    :openloop_api_key,
                    :environment,
                    :org_id,
                    :provider_id,
                    :form_ids,
                    :appointment_type_ids

      def initialize
        @healthie_api_key = nil
        @healthie_url = nil
        @healthie_authorization_shard = nil
        @openloop_questionnaire_url = nil
        @openloop_booking_widget_base_url = nil
        @openloop_api_key = nil
        @environment = :staging
        @org_id = nil
        @provider_id = nil
        @form_ids = {}
        @appointment_type_ids = {}
      end

      def healthie_url
        @healthie_url || default_healthie_url
      end

      def openloop_questionnaire_url
        @openloop_questionnaire_url || default_questionnaire_url
      end

      def openloop_booking_widget_base_url
        @openloop_booking_widget_base_url || default_booking_widget_base_url
      end

      def org_id
        @org_id || default_org_id
      end

      def provider_id
        @provider_id || default_provider_id
      end

      def form_ids
        @form_ids.empty? ? default_form_ids : @form_ids
      end

      def appointment_type_ids
        @appointment_type_ids.empty? ? default_appointment_type_ids : @appointment_type_ids
      end

      # Helper method to build booking widget URL
      def booking_widget_url(appointment_type_key)
        appointment_type_id = appointment_type_ids[appointment_type_key]
        return nil unless appointment_type_id

        "#{openloop_booking_widget_base_url}?appointmentTypeId=#{appointment_type_id}&providerId=#{provider_id}"
      end

      private

      def default_healthie_url
        environment == :production ?
          "https://api.gethealthie.com/graphql" :
          "https://staging-api.gethealthie.com/graphql"
      end

      def default_questionnaire_url
        environment == :production ?
          "https://api.questionnaire.solutions.openloophealth.com" :
          "https://api.questionnaire.solutions-staging.openloophealth.com"
      end

      def default_booking_widget_base_url
        environment == :production ?
          "https://express.patientcare.openloophealth.com/book-appointment" :
          "https://express.care-staging.openloophealth.com/book-appointment"
      end

      def default_org_id
        environment == :production ? "93721" : "167021"
      end

      def default_provider_id
        environment == :production ? "9584181" : "3483153"
      end

      def default_form_ids
        if environment == :production
          {
            trt_initial: "2471727",
            trt_refill: "2471728",
            labs_upload_completed: "2638349",
            trt_encounter_note: "2841159"
          }
        else
          {
            trt_initial: "2156890",
            trt_refill: "2156891",
            labs_upload_completed: "2190741",
            trt_encounter_note: "2190742"
          }
        end
      end

      def default_appointment_type_ids
        if environment == :production
          {
            trt_initial: "472535",
            trt_refill: "472536",
            enclomiphene_initial: "472537",
            enclomiphene_refill: "472538"
          }
        else
          {
            trt_initial: "349681",
            trt_refill: "349682",
            enclomiphene_initial: "349683",
            enclomiphene_refill: "349684"
          }
        end
      end
    end
  end
end
