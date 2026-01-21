# frozen_string_literal: true

module OpenLoop
  module Client
    module API
      # Client for interacting with OpenLoop-specific REST APIs.
      #
      # The OpenloopApiClient provides methods for TRT form submissions,
      # booking widget URL generation, and lab facility lookups. These
      # are OpenLoop-specific endpoints separate from the Healthie API.
      #
      # @example Basic usage
      #   openloop = OpenLoop::Client::API::OpenloopApiClient.new
      #
      #   # Generate booking URL
      #   url = openloop.booking_widget_url(
      #     therapy_type: 'trt',
      #     visit_type: 'initial',
      #     firstName: 'John',
      #     lastName: 'Doe'
      #   )
      #
      # @see OpenLoop::Client::Configuration Configuration for API settings
      class OpenloopApiClient < BaseClient
        # Creates a new OpenloopApiClient instance.
        #
        # @return [OpenloopApiClient] a new client instance
        def initialize
          @config = OpenLoop::Client.configuration
        end

        # Creates a TRT (Testosterone Replacement Therapy) intake form.
        #
        # @param data [Hash] form data to submit
        # @option data [String] :patient_id Patient ID (required)
        # @option data [Integer] :formReferenceId Form reference ID (required)
        # @option data [String] :modality Visit modality (e.g., "sync_visit")
        # @option data [String] :service_type Service type (e.g., "macro_trt")
        # @option data [String] :visit_type Type of visit
        # @option data [String] :medication_preference Medication preference
        # @option data [Array<String>] :q1_do_any_of_the_following_apply_to_you Form question responses
        # @return [Hash] the parsed JSON response
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.create_trt_form({
        #     patient_id: "123456",
        #     formReferenceId: 2471727,
        #     modality: "sync_visit",
        #     service_type: "macro_trt"
        #   })
        def create_trt_form(data)
          response = self.class.post(
            "#{@config.openloop_questionnaire_url}/create-form",
            body: { data: data }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          handle_response(response)
        end

        # Generates a booking widget URL with pre-filled patient information.
        #
        # @param therapy_type [String] type of therapy ("trt" or "enclomiphene")
        # @param visit_type [String] type of visit ("initial" or "refill")
        # @param params [Hash] additional URL parameters to include
        # @option params [String] :firstName Patient first name
        # @option params [String] :lastName Patient last name
        # @option params [String] :email Patient email
        # @option params [String] :phoneNumber Patient phone (digits only)
        # @option params [String] :state Patient state (2-letter code)
        # @option params [String] :zip Patient zip code
        # @option params [String] :redirectUrl URL to redirect after booking
        # @option params [Boolean] :headless Run in headless mode
        # @return [String] the complete booking widget URL
        # @raise [ArgumentError] if therapy_type or visit_type is invalid
        #
        # @example Generate TRT initial visit URL
        #   url = client.booking_widget_url(
        #     therapy_type: 'trt',
        #     visit_type: 'initial',
        #     firstName: 'John',
        #     lastName: 'Doe',
        #     email: 'john@example.com',
        #     state: 'CA',
        #     zip: '90001'
        #   )
        #
        # @example Generate enclomiphene refill URL
        #   url = client.booking_widget_url(
        #     therapy_type: 'enclomiphene',
        #     visit_type: 'refill'
        #   )
        def booking_widget_url(therapy_type: 'trt', visit_type: 'initial', **params)
          valid_therapy_types = %w[trt enclomiphene]
          valid_visit_types = %w[initial refill]

          unless valid_therapy_types.include?(therapy_type.to_s)
            raise ArgumentError, "therapy_type must be one of: #{valid_therapy_types.join(', ')}"
          end
          unless valid_visit_types.include?(visit_type.to_s)
            raise ArgumentError, "visit_type must be one of: #{valid_visit_types.join(', ')}"
          end

          query_params = {
            appointmentTypeId: @config.appointment_type_ids["#{therapy_type}_#{visit_type}".to_sym],
            providerId: @config.provider_id
          }.merge(params)

          query_string = URI.encode_www_form(query_params)
          "#{@config.openloop_booking_widget_base_url}?#{query_string}"
        end

        # Retrieves lab facilities near a given zip code.
        #
        # @param zip_code [String] the zip code to search around
        # @param radius [Integer] search radius in miles (default: 50)
        # @param include_psc_details [Boolean] include PSC details (default: true)
        # @return [Hash] response containing available lab facilities
        # @raise [APIError] if the request fails
        #
        # @example
        #   facilities = client.get_lab_facilities(zip_code: "90210", radius: 25)
        def get_lab_facilities(zip_code:, radius: 50, include_psc_details: true)
          query_params = { zip_code: zip_code, radius: radius, include_psc_details: include_psc_details }
          query_string = URI.encode_www_form(query_params)
          url = "https://api.integrations.clinic.openloophealth.com/labs/facilities?#{query_string}"

          response = self.class.get(url, headers: {})
          handle_response(response)
        end
      end
    end
  end
end
