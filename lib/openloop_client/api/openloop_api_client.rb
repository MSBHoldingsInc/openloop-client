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

        def book_appointment(params)
          query_string = URI.encode_www_form(params.merge(headless: true, urlRedirect: nil))
          url = "#{@config.openloop_booking_widget_url}?#{query_string}"

          response = self.class.post(url, headers: {})
          handle_response(response)
        end

        def get_lab_facilities(zip_code:, radius: 50)
          query_params = { zip_code: zip_code, radius: radius }
          query_string = URI.encode_www_form(query_params)
          url = "https://api.integrations.clinic.openloophealth.com/labs/facilities?#{query_string}"

          response = self.class.get(url, headers: {})
          handle_response(response)
        end
      end
    end
  end
end
