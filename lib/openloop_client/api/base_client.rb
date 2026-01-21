# frozen_string_literal: true

module OpenLoop
  module Client
    # API module containing HTTP client classes for various OpenLoop services.
    #
    # This module provides low-level API clients that communicate directly
    # with the Healthie, OpenLoop, and Vital APIs. Each client handles
    # authentication, request formatting, and response parsing.
    #
    # @see OpenLoop::Client::API::HealthieClient Healthie GraphQL API client
    # @see OpenLoop::Client::API::OpenloopApiClient OpenLoop REST API client
    # @see OpenLoop::Client::API::JunctionApiClient Vital/Junction API client
    module API
      # Base HTTP client providing common functionality for API clients.
      #
      # This abstract class provides HTTP request handling, response parsing,
      # and error handling that is shared across all API clients. It uses
      # HTTParty for HTTP operations.
      #
      # @abstract Subclass and implement specific API methods
      #
      # @example Subclassing BaseClient
      #   class MyClient < BaseClient
      #     def get_resource(id)
      #       response = self.class.get("/resource/#{id}", headers: my_headers)
      #       handle_response(response)
      #     end
      #   end
      class BaseClient
        include HTTParty

        # Error class for API-related errors with access to the HTTP response.
        #
        # @example Handling API errors
        #   begin
        #     client.get_patient('invalid-id')
        #   rescue OpenLoop::Client::API::BaseClient::APIError => e
        #     puts "Error: #{e.message}"
        #     puts "HTTP Status: #{e.response.code}" if e.response
        #   end
        class APIError < StandardError
          # @return [HTTParty::Response, nil] the HTTP response that caused the error
          attr_reader :response

          # Creates a new APIError with the given message and optional response.
          #
          # @param message [String] the error message
          # @param response [HTTParty::Response, nil] the HTTP response object
          def initialize(message, response = nil)
            super(message)
            @response = response
          end
        end

        private

        # Handles an HTTP response and returns parsed data or raises an error.
        #
        # @api private
        # @param response [HTTParty::Response] the HTTP response to handle
        # @return [Hash] parsed JSON response for successful requests
        # @raise [APIError] for any non-2xx response status
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

        # Parses a successful JSON response.
        #
        # @api private
        # @param response [HTTParty::Response] the HTTP response to parse
        # @return [Hash] parsed JSON data
        # @raise [APIError] if the response body is not valid JSON
        def parse_success_response(response)
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise APIError.new("Invalid JSON response: #{e.message}", response)
        end
      end
    end
  end
end
