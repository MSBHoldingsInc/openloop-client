# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Queries
        class BaseQuery < ::GraphQL::Schema::Resolver
          protected

          def healthie_client
            @healthie_client ||= API::HealthieClient.new
          end

          def openloop_client
            @openloop_client ||= API::OpenloopApiClient.new
          end
        end
      end
    end
  end
end
