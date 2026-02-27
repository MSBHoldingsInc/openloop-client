# frozen_string_literal: true

module OpenLoop
  module Client
    module API
      class JunctionApiClient < BaseClient
        def initialize
          @config = OpenLoop::Client.configuration
        end

        def get_lab_results(order_id:)
          url = "#{@config.vital_api_url}/order/#{order_id}/result"
          headers = { "x-vital-api-key" => @config.vital_api_key }

          response = self.class.get(url, headers: headers)
          handle_response(response)
        end

        def get_order_psc_info(order_id:, radius: 50)
          url = "#{@config.vital_api_url}/order/#{order_id}/psc/info"
          headers = {
            "x-vital-api-key" => @config.vital_api_key,
            "accept" => "application/json"
          }
          query = { radius: radius }

          response = self.class.get(url, headers: headers, query: query)
          handle_response(response)
        end

        # https://docs.junction.com/api-reference/lab-testing/area-info
        # @param zip_code [String, Integer]
        # @param radius [Integer]
        # @return [Hash]
        def get_area_info(zip_code:, radius: 50)
          url = "#{@config.vital_api_url}/order/area/info"
          headers = {
            "x-vital-api-key" => @config.vital_api_key,
            "accept" => "application/json"
          }
          query = { zip_code: zip_code, radius: radius }

          response = self.class.get(url, headers: headers, query: query)
          handle_response(response)
        end

        # https://docs.junction.com/api-reference/lab-testing/requisition-pdf
        # @raise [OpenLoop::Client::API::BaseClient::APIError] if the response is not successful
        # @param order_id [String] the ID of the lab order
        # @return [String] the PDF content of the lab requisition
        def get_lab_requisition(order_id:)
          url = "#{@config.vital_api_url}/order/#{order_id}/requisition/pdf"
          headers = {
            "x-vital-api-key" => @config.vital_api_key,
            "accept" => "application/pdf"
          }
          response = self.class.get(url, headers: headers)
          return response.body if response.success?

          handle_response(response)
        end

        # https://docs.junction.com/api-reference/lab-testing/psc-info
        # @param zip_code [String, Integer]
        # @param lab_id [Integer]
        # @param radius [Integer]
        # @return [Hash]
        def get_psc_info(zip_code:, lab_id:, radius: 50)
          url = "#{@config.vital_api_url}/order/psc/info"
          headers = {
            "x-vital-api-key" => @config.vital_api_key,
            "accept" => "application/json"
          }
          query = { zip_code: zip_code, lab_id: lab_id, radius: radius }

          response = self.class.get(url, headers: headers, query: query)
          handle_response(response)
        end
      end
    end
  end
end
