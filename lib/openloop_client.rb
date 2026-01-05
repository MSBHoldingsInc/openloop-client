# frozen_string_literal: true

require "httparty"
require "graphql"

require_relative "openloop_client/version"
require_relative "openloop_client/configuration"
require_relative "openloop_client/api/base_client"
require_relative "openloop_client/api/healthie_client"
require_relative "openloop_client/api/openloop_api_client"
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

module OpenLoop
  module Client
    class Error < StandardError; end

    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def self.reset_configuration
      self.configuration = Configuration.new
    end
  end
end
