# frozen_string_literal: true

module OpenLoop
  module Client
    module API
      class BaseClient
        include HTTParty

        class APIError < StandardError
          attr_reader :response

          def initialize(message, response = nil)
            super(message)
            @response = response
          end
        end

        private

        def handle_response(response)
          case response.code
          when 200..299
            parse_success_response(response)
          when 400
            raise APIError.new("Bad Request: #{response.body}", response)
          when 401
            raise APIError.new("Unauthorized: Check your API credentials", response)
          when 404
            raise APIError.new("Not Found: #{response.body}", response)
          when 500..599
            raise APIError.new("Server Error: #{response.body}", response)
          else
            raise APIError.new("Unexpected response code #{response.code}: #{response.body}", response)
          end
        end

        def parse_success_response(response)
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise APIError.new("Invalid JSON response: #{e.message}", response)
        end
      end
    end
  end
end
