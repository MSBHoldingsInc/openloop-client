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
      end
    end
  end
end
