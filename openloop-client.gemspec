# frozen_string_literal: true

require_relative "lib/openloop_client/version"

Gem::Specification.new do |spec|
  spec.name = "openloop-client"
  spec.version = OpenLoop::Client::VERSION
  spec.authors = ["Nitesh Varma"]
  spec.email = ["nitesh@rugiet.com"]

  spec.summary = "GraphQL API client for OpenLoop Health APIs"
  spec.description = "A Rails gem that provides GraphQL interface to OpenLoop Health and Healthie APIs for patient management, forms, and appointments."
  spec.homepage = "https://github.com/MSBHoldingsInc/openloop-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/MSBHoldingsInc/openloop-client"
  spec.metadata["changelog_uri"] = "https://github.com/MSBHoldingsInc/openloop-client/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "graphql", "~> 2.0"
  spec.add_dependency "graphiql-rails", "~> 1.8"
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "rails", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
end
