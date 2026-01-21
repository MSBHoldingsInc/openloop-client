# frozen_string_literal: true

require "httparty"
require "graphql"

require_relative "openloop_client/version"
require_relative "openloop_client/configuration"
require_relative "openloop_client/api/base_client"
require_relative "openloop_client/api/healthie_client"
require_relative "openloop_client/api/openloop_api_client"
require_relative "openloop_client/api/junction_api_client"
require_relative "openloop_client/engine" if defined?(Rails)
require_relative "openloop_client/graphql/types/base_object"
require_relative "openloop_client/graphql/types/location_type"
require_relative "openloop_client/graphql/types/patient_type"
require_relative "openloop_client/graphql/types/appointment_type"
require_relative "openloop_client/graphql/types/document_type"
require_relative "openloop_client/graphql/types/form_response_type"
require_relative "openloop_client/graphql/mutations/base_mutation"
require_relative "openloop_client/graphql/mutations/create_patient"
require_relative "openloop_client/graphql/mutations/update_patient"
require_relative "openloop_client/graphql/mutations/upload_document"
require_relative "openloop_client/graphql/mutations/create_metric_entry"
require_relative "openloop_client/graphql/mutations/create_invoice"
require_relative "openloop_client/graphql/mutations/create_trt_form"
require_relative "openloop_client/graphql/queries/base_query"
require_relative "openloop_client/graphql/queries/patient"
require_relative "openloop_client/graphql/queries/search_patients"
require_relative "openloop_client/graphql/queries/patient_appointments"
require_relative "openloop_client/graphql/schema"

# Top-level namespace for the OpenLoop Health API client gem.
#
# @example Basic configuration
#   OpenLoop::Client.configure do |config|
#     config.openloop_api_key = ENV['OPENLOOP_API_KEY']
#     config.healthie_authorization_shard = ENV['HEALTHIE_AUTHORIZATION_SHARD']
#     config.environment = :staging
#   end
#
# @see OpenLoop::Client Main client module
# @see OpenLoop::Client::Configuration Configuration options
module OpenLoop
  # Client module providing access to OpenLoop Health and Healthie APIs.
  #
  # This module serves as the main entry point for configuring and using
  # the OpenLoop client library. It provides:
  #
  # - Configuration management for API credentials and environment settings
  # - REST API clients for Healthie, OpenLoop, and Vital (Junction) APIs
  # - A GraphQL schema wrapping the underlying REST APIs
  #
  # @example Configure the client
  #   OpenLoop::Client.configure do |config|
  #     config.openloop_api_key = 'your-api-key'
  #     config.healthie_authorization_shard = 'your-shard-id'
  #     config.vital_api_key = 'your-vital-key'
  #     config.environment = :production
  #   end
  #
  # @example Use the Healthie API client directly
  #   healthie = OpenLoop::Client::API::HealthieClient.new
  #   patient = healthie.get_patient('123456')
  #
  # @example Execute a GraphQL query
  #   query = '{ patient(id: "123") { name email } }'
  #   result = OpenLoop::Client::GraphQL::Schema.execute(query)
  #
  # @see OpenLoop::Client::Configuration Configuration class
  # @see OpenLoop::Client::API::HealthieClient Healthie API client
  # @see OpenLoop::Client::API::OpenloopApiClient OpenLoop API client
  # @see OpenLoop::Client::API::JunctionApiClient Vital/Junction API client
  module Client
    # Base error class for all OpenLoop client errors.
    #
    # @example Rescue from any OpenLoop client error
    #   begin
    #     client.get_patient('invalid-id')
    #   rescue OpenLoop::Client::Error => e
    #     puts "Error: #{e.message}"
    #   end
    class Error < StandardError; end

    class << self
      # @!attribute [rw] configuration
      #   @return [Configuration, nil] the current configuration instance
      attr_accessor :configuration
    end

    # Configures the OpenLoop client with the given settings.
    #
    # This method yields a {Configuration} instance that can be used to set
    # API credentials, environment, and other options. Configuration is typically
    # done once during application initialization.
    #
    # @yield [Configuration] the configuration instance to modify
    # @return [Configuration] the configuration instance
    #
    # @example Configure in a Rails initializer
    #   # config/initializers/openloop_client.rb
    #   OpenLoop::Client.configure do |config|
    #     config.healthie_api_key = ENV['HEALTHIE_API_KEY']
    #     config.openloop_api_key = ENV['OPENLOOP_API_KEY']
    #     config.vital_api_key = ENV['VITAL_API_KEY']
    #     config.environment = Rails.env.production? ? :production : :staging
    #   end
    #
    # @see Configuration
    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    # Resets the configuration to default values.
    #
    # This method creates a new {Configuration} instance with default settings,
    # discarding any previous configuration. Useful for testing.
    #
    # @return [Configuration] the new configuration instance
    #
    # @example Reset configuration in tests
    #   before(:each) do
    #     OpenLoop::Client.reset_configuration
    #   end
    def self.reset_configuration
      self.configuration = Configuration.new
    end
  end
end
