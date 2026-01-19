# frozen_string_literal: true

module OpenLoop
  module Client
    module API
      class OpenloopApiClient < BaseClient
        def initialize
          @config = OpenLoop::Client.configuration
        end

        def create_trt_form(data)
          response = self.class.post(
            "#{@config.openloop_questionnaire_url}/create-form",
            body: { data: data }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
          handle_response(response)
        end

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
