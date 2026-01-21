# frozen_string_literal: true

module OpenLoop
  module Client
    module API
      # Client for interacting with the Vital (Junction) API for lab results.
      #
      # The JunctionApiClient provides methods for retrieving lab test results
      # from the Vital API. This requires a valid vital_api_key to be configured.
      #
      # @example Basic usage
      #   junction = OpenLoop::Client::API::JunctionApiClient.new
      #   results = junction.get_lab_results(order_id: "550e8400-e29b-41d4-a716-446655440000")
      #   puts results["metadata"]
      #   puts results["results"]
      #
      # @see OpenLoop::Client::Configuration Configuration for vital_api_key
      class JunctionApiClient < BaseClient
        # Creates a new JunctionApiClient instance.
        #
        # @return [JunctionApiClient] a new client instance
        def initialize
          @config = OpenLoop::Client.configuration
        end

        # Retrieves lab test results for a specific order.
        #
        # @param order_id [String] the Vital order ID (UUID format)
        # @return [Hash] response containing metadata and results arrays
        # @raise [APIError] if the request fails or order not found
        #
        # @example
        #   results = client.get_lab_results(order_id: "550e8400-e29b-41d4-a716-446655440000")
        #
        #   # Access metadata
        #   puts results["metadata"]["patient"]
        #   puts results["metadata"]["date_reported"]
        #
        #   # Access biomarker results
        #   results["results"].each do |biomarker|
        #     puts "#{biomarker['name']}: #{biomarker['value']} #{biomarker['unit']}"
        #   end
        def get_lab_results(order_id:)
          url = "#{@config.vital_api_url}/order/#{order_id}/result"
          headers = { "x-vital-api-key" => @config.vital_api_key }

          response = self.class.get(url, headers: headers)
          handle_response(response)
        end
      end
    end
  end
end
