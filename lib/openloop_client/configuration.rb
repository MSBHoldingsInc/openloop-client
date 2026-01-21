# frozen_string_literal: true

module OpenLoop
  module Client
    # Stores configuration settings for the OpenLoop client.
    #
    # Configuration is typically done through {OpenLoop::Client.configure}
    # in an initializer file. The configuration handles API credentials,
    # environment selection, and provides environment-specific URLs and IDs.
    #
    # @example Configure the client
    #   OpenLoop::Client.configure do |config|
    #     config.healthie_api_key = ENV['HEALTHIE_API_KEY']
    #     config.openloop_api_key = ENV['OPENLOOP_API_KEY']
    #     config.healthie_authorization_shard = ENV['HEALTHIE_SHARD']
    #     config.vital_api_key = ENV['VITAL_API_KEY']
    #     config.environment = :production
    #   end
    #
    # @example Access configuration values
    #   config = OpenLoop::Client.configuration
    #   config.healthie_url  # => "https://api.gethealthie.com/graphql"
    #   config.provider_id   # => "9584181" (production)
    #
    # @see OpenLoop::Client.configure
    class Configuration
      # @!attribute [rw] healthie_api_key
      #   API key for direct Healthie API authentication (Basic auth).
      #   Use this OR openloop_api_key + healthie_authorization_shard.
      #   @return [String, nil] the Healthie API key

      # @!attribute [rw] healthie_authorization_shard
      #   Shard ID for multi-tenant Healthie authentication.
      #   Required when using openloop_api_key for Bearer token auth.
      #   @return [String, nil] the Healthie shard ID

      # @!attribute [rw] openloop_api_key
      #   Bearer token for OpenLoop API authentication.
      #   Provides access to OpenLoop endpoints and Healthie via proxy.
      #   @return [String, nil] the OpenLoop API key

      # @!attribute [rw] vital_api_key
      #   API key for Vital (Junction) lab results API.
      #   Required for retrieving lab test results.
      #   @return [String, nil] the Vital API key

      # @!attribute [rw] environment
      #   Current environment setting (:staging or :production).
      #   Determines which API endpoints and IDs are used.
      #   @return [Symbol] the environment (:staging or :production)
      attr_accessor :healthie_api_key,
                    :healthie_authorization_shard,
                    :openloop_api_key,
                    :vital_api_key,
                    :environment

      # Creates a new Configuration instance with default values.
      #
      # @return [Configuration] a new configuration with staging defaults
      def initialize
        @healthie_api_key = nil
        @healthie_authorization_shard = nil
        @openloop_api_key = nil
        @vital_api_key = nil
        @environment = :staging
      end

      # Returns the Healthie GraphQL API URL for the current environment.
      #
      # @return [String] the Healthie API URL
      # @example
      #   config.environment = :production
      #   config.healthie_url  # => "https://api.gethealthie.com/graphql"
      def healthie_url
        default_healthie_url
      end

      # Returns the OpenLoop questionnaire API URL for the current environment.
      #
      # @return [String] the questionnaire API URL
      def openloop_questionnaire_url
        default_questionnaire_url
      end

      # Returns the booking widget base URL for the current environment.
      #
      # @return [String] the booking widget base URL
      def openloop_booking_widget_base_url
        default_booking_widget_base_url
      end

      # Returns the organization ID for the current environment.
      #
      # @return [String] the organization ID
      def org_id
        default_org_id
      end

      # Returns the default provider ID for the current environment.
      #
      # @return [String] the provider ID
      # @example
      #   config.environment = :staging
      #   config.provider_id  # => "3483153"
      def provider_id
        default_provider_id
      end

      # Returns form IDs for the current environment.
      #
      # @return [Hash{Symbol => String}] hash of form type to form ID mappings
      # @example
      #   config.form_ids[:trt_initial]  # => "2156890" (staging)
      def form_ids
        default_form_ids
      end

      # Returns appointment type IDs for the current environment.
      #
      # @return [Hash{Symbol => String}] hash of appointment type to ID mappings
      # @example
      #   config.appointment_type_ids[:trt_initial]  # => "349681" (staging)
      def appointment_type_ids
        default_appointment_type_ids
      end

      # Returns the Vital API URL for the current environment.
      #
      # @return [String] the Vital API URL
      def vital_api_url
        default_vital_api_url
      end

      # Builds a complete booking widget URL for the given appointment type.
      #
      # @param appointment_type_key [Symbol] the appointment type key
      #   (e.g., :trt_initial, :trt_refill, :enclomiphene_initial)
      # @return [String, nil] the complete booking widget URL, or nil if
      #   the appointment type key is not found
      #
      # @example
      #   config.booking_widget_url(:trt_initial)
      #   # => "https://express.care-staging.openloophealth.com/book-appointment?appointmentTypeId=349681&providerId=3483153"
      def booking_widget_url(appointment_type_key)
        appointment_type_id = appointment_type_ids[appointment_type_key]
        return nil unless appointment_type_id

        "#{openloop_booking_widget_base_url}?appointmentTypeId=#{appointment_type_id}&providerId=#{provider_id}"
      end

      private

      # @api private
      def default_healthie_url
        environment == :production ?
          "https://api.gethealthie.com/graphql" :
          "https://staging-api.gethealthie.com/graphql"
      end

      # @api private
      def default_questionnaire_url
        environment == :production ?
          "https://api.questionnaire.solutions.openloophealth.com" :
          "https://api.questionnaire.solutions-staging.openloophealth.com"
      end

      # @api private
      def default_booking_widget_base_url
        environment == :production ?
          "https://express.patientcare.openloophealth.com/book-appointment" :
          "https://express.care-staging.openloophealth.com/book-appointment"
      end

      # @api private
      def default_vital_api_url
        environment == :production ?
          "https://api.tryvital.io/v3" :
          "https://api.sandbox.tryvital.io/v3"
      end

      # @api private
      def default_org_id
        environment == :production ? "93721" : "167021"
      end

      # @api private
      def default_provider_id
        environment == :production ? "9584181" : "3483153"
      end

      # @api private
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

      # @api private
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
