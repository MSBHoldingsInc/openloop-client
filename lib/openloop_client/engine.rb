# frozen_string_literal: true

require "graphiql/rails"

module OpenLoop
  module Client
    class Engine < ::Rails::Engine
      isolate_namespace OpenLoop::Client

      config.generators do |g|
        g.test_framework :rspec
      end
    end
  end
end
