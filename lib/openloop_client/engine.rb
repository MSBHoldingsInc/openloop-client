# frozen_string_literal: true

require "graphiql/rails"

module OpenLoop
  module Client
    # Rails Engine for mounting OpenLoop client routes and configurations.
    #
    # The Engine provides Rails integration including:
    # - Isolated namespace for avoiding conflicts
    # - GraphiQL interface for API exploration (when mounted)
    # - RSpec test framework configuration
    #
    # @example Mount the engine in routes.rb
    #   # config/routes.rb
    #   Rails.application.routes.draw do
    #     mount OpenLoop::Client::Engine => "/openloop"
    #   end
    #
    # @note This class is only loaded when Rails is defined
    class Engine < ::Rails::Engine
      isolate_namespace OpenLoop::Client

      config.generators do |g|
        g.test_framework :rspec
      end
    end
  end
end
