# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      # GraphQL type definitions for the OpenLoop client schema.
      #
      # This module contains all GraphQL object types used in queries
      # and mutations. Types map API responses to GraphQL fields.
      #
      # @see OpenLoop::Client::GraphQL::Schema The GraphQL schema
      module Types
        # Base class for all GraphQL object types in the OpenLoop schema.
        #
        # All type classes should inherit from this base class to ensure
        # consistent behavior and configuration.
        #
        # @abstract Subclass to create new GraphQL types
        class BaseObject < ::GraphQL::Schema::Object
        end
      end
    end
  end
end
