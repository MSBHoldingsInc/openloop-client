# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      # GraphQL mutation resolvers for the OpenLoop client schema.
      #
      # Mutations provide write operations for creating and updating
      # patients, uploading documents, creating forms, and more.
      #
      # @see OpenLoop::Client::GraphQL::Mutations::CreatePatient
      # @see OpenLoop::Client::GraphQL::Mutations::UpdatePatient
      # @see OpenLoop::Client::GraphQL::Mutations::UploadDocument
      # @see OpenLoop::Client::GraphQL::Mutations::CreateMetricEntry
      # @see OpenLoop::Client::GraphQL::Mutations::CreateInvoice
      # @see OpenLoop::Client::GraphQL::Mutations::CreateTrtForm
      module Mutations
        # Base class for all GraphQL mutation resolvers.
        #
        # Provides access to API clients for use in subclass resolvers.
        # All mutation classes should inherit from this base.
        #
        # @abstract Subclass and implement the resolve method
        class BaseMutation < ::GraphQL::Schema::Mutation
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
