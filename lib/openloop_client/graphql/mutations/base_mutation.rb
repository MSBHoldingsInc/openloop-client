# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        class BaseMutation < ::GraphQL::Schema::Mutation
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
