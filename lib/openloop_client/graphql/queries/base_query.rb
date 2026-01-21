# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      # GraphQL query resolvers for the OpenLoop client schema.
      #
      # Queries provide read-only access to patient and appointment data
      # through the GraphQL interface.
      #
      # @see OpenLoop::Client::GraphQL::Queries::Patient
      # @see OpenLoop::Client::GraphQL::Queries::SearchPatients
      # @see OpenLoop::Client::GraphQL::Queries::PatientAppointments
      module Queries
        # Base class for all GraphQL query resolvers.
        #
        # Provides access to API clients for use in subclass resolvers.
        # All query classes should inherit from this base.
        #
        # @abstract Subclass and implement the resolve method
        class BaseQuery < ::GraphQL::Schema::Resolver
          protected

          # Returns a Healthie API client instance.
          # @api private
          # @return [API::HealthieClient] memoized client instance
          def healthie_client
            @healthie_client ||= API::HealthieClient.new
          end

          # Returns an OpenLoop API client instance.
          # @api private
          # @return [API::OpenloopApiClient] memoized client instance
          def openloop_client
            @openloop_client ||= API::OpenloopApiClient.new
          end
        end
      end
    end
  end
end
