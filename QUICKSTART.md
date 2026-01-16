# OpenLoop::Client - Quick Start Guide

This guide will help you get started with the OpenLoop::Client gem in minutes.

## Installation

### 1. Add to your Gemfile

```ruby
gem 'openloop-client', path: '/path/to/openloop-client'
# Or from git once published
# gem 'openloop-client', git: 'https://github.com/MSBHoldingsInc/openloop-client'
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Configure the gem

Create `config/initializers/openloop_client.rb`:

```ruby
OpenLoop::Client.configure do |config|
  # Healthie API
  config.healthie_api_key = ENV['HEALTHIE_API_KEY']

  # OpenLoop API (optional - for Bearer token auth)
  config.openloop_api_key = ENV['OPENLOOP_API_KEY']
  config.healthie_authorization_shard = ENV['HEALTHIE_AUTHORIZATION_SHARD']

  # Vital API (optional - for lab results)
  config.vital_api_key = ENV['VITAL_API_KEY']

  # Environment
  config.environment = Rails.env.production? ? :production : :staging
end
```

### 4. Set up environment variables

Create `.env` file (use dotenv gem or Rails credentials):

```bash
# For staging
HEALTHIE_API_KEY=your_healthie_api_key_here
OPENLOOP_API_KEY=your_openloop_api_key_here
HEALTHIE_AUTHORIZATION_SHARD=your_shard_id_here
VITAL_API_KEY=your_vital_api_key_here
```

### 5. Set up GraphQL endpoint

#### Add route in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"

  # Development only - GraphiQL interface
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
end
```

#### Create controller `app/controllers/graphql_controller.rb`:

```ruby
class GraphqlController < ApplicationController
  skip_before_action :verify_authenticity_token

  def execute
    result = OpenLoop::Client::GraphQL::Schema.execute(
      params[:query],
      variables: ensure_hash(params[:variables]),
      context: {},
      operation_name: params[:operationName]
    )
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      ambiguous_param.present? ? JSON.parse(ambiguous_param) : {}
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")
    render json: {
      errors: [{ message: e.message, backtrace: e.backtrace }],
      data: {}
    }, status: 500
  end
end
```

### 6. Start your Rails server

```bash
rails server
```

### 7. Test the GraphiQL interface

Visit `http://localhost:3000/graphiql` and try this query:

```graphql
query {
  searchPatients(keywords: "test") {
    id
    name
    email
  }
}
```

## Your First API Call

### Using GraphQL (Recommended)

```ruby
# In your Rails console or controller
result = OpenLoop::Client::GraphQL::Schema.execute(
  <<~GRAPHQL
    query {
      patient(id: "123456") {
        id
        firstName
        lastName
        email
      }
    }
  GRAPHQL
)

patient = result["data"]["patient"]
puts "Patient: #{patient['firstName']} #{patient['lastName']}"
```

### Using Direct API Client

```ruby
# In your Rails console or service object
healthie = OpenLoop::Client::API::HealthieClient.new

# Search for patients
patients = healthie.search_patients("john")
puts patients.dig("data", "users")

# Get patient details
patient = healthie.get_patient("123456")
puts patient.dig("data", "user", "name")

# Get appointment details
appointment = healthie.get_appointment("2037619")
appointment_data = appointment.dig("data", "appointment")
puts "Appointment Date: #{appointment_data['date']}"
puts "Provider: #{appointment_data.dig('provider', 'name')}"

# Create a new patient
new_patient = healthie.create_patient({
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  phone_number: "555-123-4567",
  dietitian_id: "789"
})
patient_id = new_patient.dig("data", "createClient", "user", "id")
puts "Created patient with ID: #{patient_id}"
```

## Common Operations

### 1. Create Patient Workflow

```ruby
# Step 1: Get dietitian ID from configuration
healthie = OpenLoop::Client::API::HealthieClient.new
config = OpenLoop::Client.configuration
dietitian_id = config.provider_id

# Step 2: Create patient
patient = healthie.create_patient({
  first_name: "Jane",
  last_name: "Smith",
  email: "jane@example.com",
  phone_number: "555-9876",
  dietitian_id: dietitian_id,
  additional_record_identifier: "A7654321"
})

patient_id = patient.dig("data", "createClient", "user", "id")

# Step 3: Update patient with address
healthie.update_patient({
  id: patient_id,
  dob: "05/15/1985",
  gender: "Female",
  height: "65",
  location: {
    line1: "456 Oak Ave",
    city: "Los Angeles",
    state: "CA",
    zip: "90001",
    country: "US"
  }
})
```

### 2. Submit TRT Form

```ruby
openloop = OpenLoop::Client::API::OpenloopApiClient.new

form_response = openloop.create_trt_form({
  patient_id: patient_id,
  formReferenceId: 2471727,
  modality: "sync_visit",
  service_type: "macro_trt",
  visit_type: "Initial Visit ( visit_type_1 )",
  medication_preference: "Testosterone Cypionate Injection + Anastrozole (as merited) ( med_trt )",
  labs_will_be_ordered_through: "( order_vital_labs ) ( trt_initial_panel )",
  q1_do_any_of_the_following_apply_to_you: ["None of the above"],
  q8_current_medications_updates: ["None"],
  "9_medication_and_allergy_history": ["None of the above"]
})
```

### 3. Upload Lab Results

```ruby
# Read and encode file
file_data = File.read("path/to/lab_results.pdf")
base64_string = "data:application/pdf;base64,#{Base64.strict_encode64(file_data)}"

healthie.upload_document({
  file_string: base64_string,
  display_name: "Lab Results - #{Date.today}",
  rel_user_id: patient_id
})
```

### 4. Record Metrics

```ruby
healthie.create_metric_entry({
  category: "Weight",
  type: "MetricEntry",
  metric_stat: "185",
  user_id: patient_id,
  created_at: Date.today.strftime("%-m/%-d/%Y")
})
```

### 5. Get Lab Test Results

```ruby
junction = OpenLoop::Client::API::JunctionApiClient.new

# Retrieve lab results using Vital order ID
order_id = "550e8400-e29b-41d4-a716-446655440000"
results = junction.get_lab_results(order_id: order_id)

# Access results
puts "Patient: #{results['metadata']['patient_name']}"
puts "Collection Date: #{results['metadata']['sample_collection_date']}"
results["results"].each do |biomarker|
  puts "#{biomarker['name']}: #{biomarker['value']} #{biomarker['unit']}"
end
```

## GraphQL Examples

### Search and Display Patients

```graphql
query SearchPatients {
  searchPatients(keywords: "smith") {
    id
    name
    email
    phoneNumber
    dob
    location {
      city
      state
    }
  }
}
```

### Create Patient

```graphql
mutation CreatePatient {
  createPatient(
    firstName: "John"
    lastName: "Doe"
    email: "john.doe@example.com"
    phoneNumber: "555-123-4567"
    dietitianId: "789"
  ) {
    patient {
      id
      firstName
      lastName
      email
    }
    errors
  }
}
```

### Get Patient Appointments

```graphql
query GetAppointments {
  patientAppointments(userId: "123456") {
    id
    date
    contactType
    length
    providerName
    appointmentTypeName
  }
}
```

## Troubleshooting

### "Unauthorized" Error

Make sure your API keys are correctly set in the environment:
- `HEALTHIE_API_KEY` for Basic auth
- OR `OPENLOOP_API_KEY` + `HEALTHIE_AUTHORIZATION_SHARD` for Bearer token auth

### "GraphQL Schema not found"

Ensure you've mounted the GraphQL endpoint in your routes and created the controller.

### "Connection refused"

Check that:
1. Your environment variables are set correctly
2. The API URLs are correct for your environment (staging vs production)
3. You have network access to the APIs

## Next Steps

- Read the full [README.md](README.md) for comprehensive documentation
- Check out [EXAMPLES.md](EXAMPLES.md) for more code examples
- Review the [CHANGELOG.md](CHANGELOG.md) for version history
- Explore the GraphiQL interface at `/graphiql` in development

## Need Help?

- Check the gem documentation: `bundle open openloop-client`
- Review API responses in Rails logs
- Use GraphiQL interface to test queries interactively
- Check Healthie API documentation for field details

## Production Checklist

Before deploying to production:

- [ ] Set `config.environment = :production`
- [ ] Use production API keys
- [ ] Remove or restrict GraphiQL access
- [ ] Set up proper error handling and logging
- [ ] Configure rate limiting if needed
- [ ] Test all critical workflows
- [ ] Set up monitoring for API calls

## Architecture Overview

```
Your Rails App
    ↓
GraphQL Controller (app/controllers/graphql_controller.rb)
    ↓
OpenLoop::Client::GraphQL::Schema
    ↓
┌─────────────────────┬──────────────────────┐
│   Queries           │    Mutations         │
│  - patient          │  - createPatient     │
│  - searchPatients   │  - updatePatient     │
│  - appointments     │  - uploadDocument    │
└─────────────────────┴──────────────────────┘
    ↓                           ↓
┌─────────────────────┬──────────────────────┐
│  HealthieClient     │  OpenloopApiClient   │
│  (GraphQL API)      │  (REST API)          │
└─────────────────────┴──────────────────────┘
    ↓                           ↓
Healthie API              OpenLoop API
```
