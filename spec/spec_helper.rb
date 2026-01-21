# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_group "API Clients", "lib/openloop_client/api"
  add_group "GraphQL", "lib/openloop_client/graphql"
  add_group "Configuration", "lib/openloop_client/configuration.rb"
  minimum_coverage 80
end

require "openloop_client"
require "webmock/rspec"

# Disable external HTTP connections during tests
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    OpenLoop::Client.reset_configuration
    OpenLoop::Client.configure do |c|
      c.openloop_api_key = "test-api-key"
      c.healthie_authorization_shard = "test-shard"
      c.vital_api_key = "test-vital-key"
      c.environment = :staging
    end
  end

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed
end

# Helper module for building mock responses
module MockResponses
  def self.healthie_patient_response(id: "123456", first_name: "John", last_name: "Doe")
    {
      "data" => {
        "user" => {
          "id" => id,
          "name" => "#{first_name} #{last_name}",
          "first_name" => first_name,
          "last_name" => last_name,
          "email" => "#{first_name.downcase}@example.com",
          "phone_number" => "555-123-4567",
          "dob" => "01/15/1990",
          "gender" => "Male",
          "height" => "72",
          "weight" => "180",
          "age" => 34,
          "timezone" => "America/New_York",
          "dietitian_id" => "789",
          "created_at" => "2024-01-01T00:00:00Z",
          "updated_at" => "2024-01-15T00:00:00Z",
          "location" => {
            "line1" => "123 Main St",
            "line2" => nil,
            "city" => "Austin",
            "state" => "TX",
            "zip" => "78701",
            "country" => "US"
          }
        }
      }
    }
  end

  def self.healthie_create_patient_response(id: "123456", first_name: "John", last_name: "Doe")
    {
      "data" => {
        "createClient" => {
          "user" => {
            "id" => id,
            "first_name" => first_name,
            "last_name" => last_name,
            "email" => "#{first_name.downcase}@example.com",
            "phone_number" => "555-123-4567",
            "dietitian_id" => "789",
            "skipped_email" => false,
            "user_group_id" => nil,
            "additional_record_identifier" => nil
          },
          "messages" => []
        }
      }
    }
  end

  def self.healthie_search_response(users: [])
    {
      "data" => {
        "users" => users.map do |u|
          {
            "id" => u[:id] || "123",
            "name" => "#{u[:first_name]} #{u[:last_name]}",
            "email" => u[:email] || "test@example.com",
            "first_name" => u[:first_name] || "Test",
            "last_name" => u[:last_name] || "User",
            "phone_number" => "555-0000",
            "dob" => "01/01/1990",
            "gender" => "Male"
          }
        end
      }
    }
  end

  def self.healthie_appointments_response(appointments: [])
    {
      "data" => {
        "appointmentsCount" => appointments.length,
        "appointments" => appointments.map do |a|
          {
            "id" => a[:id] || "999",
            "date" => a[:date] || "2024-01-20T10:00:00Z",
            "contact_type" => "Video",
            "created_at" => "2024-01-01T00:00:00Z",
            "length" => 30,
            "location" => nil,
            "provider" => { "full_name" => "Dr. Smith" },
            "appointment_type" => { "name" => "TRT Initial", "id" => "123" },
            "attendees" => []
          }
        end
      }
    }
  end

  def self.healthie_appointment_response(id: "999")
    {
      "data" => {
        "appointment" => {
          "id" => id,
          "length" => 30,
          "date" => "2024-01-20T10:00:00Z",
          "pm_status" => "Scheduled",
          "user_id" => "123456",
          "updated_at" => "2024-01-15T00:00:00Z",
          "timezone_abbr" => "EST",
          "external_videochat_url" => "https://video.example.com/123",
          "provider" => {
            "name" => "Dr. Smith",
            "id" => "789",
            "email" => "dr.smith@example.com",
            "npi" => "1234567890",
            "organization" => { "name" => "OpenLoop Health", "id" => "1" }
          },
          "appointment_type" => { "id" => "123" },
          "requested_payment" => nil,
          "user" => {
            "id" => "123456",
            "first_name" => "John",
            "last_name" => "Doe",
            "full_name" => "John Doe",
            "email" => "john@example.com"
          }
        }
      }
    }
  end

  def self.healthie_error_response(field: "email", message: "is invalid")
    {
      "data" => {
        "createClient" => {
          "user" => nil,
          "messages" => [{ "field" => field, "message" => message }]
        }
      }
    }
  end

  def self.vital_lab_results_response
    {
      "metadata" => {
        "patient" => "John Doe",
        "age" => 34,
        "date_reported" => "2024-01-15"
      },
      "results" => [
        {
          "name" => "Testosterone, Total",
          "value" => 650,
          "unit" => "ng/dL",
          "min_range_value" => 300,
          "max_range_value" => 1000,
          "is_above_max_range" => false,
          "is_below_min_range" => false
        }
      ]
    }
  end
end
