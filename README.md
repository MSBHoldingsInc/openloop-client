# OpenLoop::Client

A Rails gem that provides a GraphQL interface to OpenLoop Health and Healthie APIs for patient management, forms, and appointments. Built with scalability in mind, making it easy to add new resources and endpoints.

## Features

- GraphQL API wrapper for OpenLoop Health and Healthie APIs
- Patient management (CRUD operations)
- Document uploads
- Metric entries (weight, etc.)
- Invoice creation
- TRT form submissions
- Appointment management
- GraphiQL interface for API exploration
- HTTParty-based REST client
- Configurable for staging and production environments
- Modular architecture for easy extension

## Installation

### Option 1: Install from local path (Development)

Add this line to your Rails application's Gemfile:

```ruby
gem 'openloop-client', path: '../openloop-client'
```

Then execute:

```bash
bundle install
```

### Option 2: Install from git (Once pushed to repository)

```ruby
gem 'openloop-client', git: 'https://github.com/openloop/openloop-client'
```

Then execute:

```bash
bundle install
```

### Option 3: Install from RubyGems (Once published)

```ruby
gem 'openloop-client'
```

Then execute:

```bash
bundle install
```

## Configuration

### Step 1: Create Initializer

Create a new file `config/initializers/openloop_client.rb` in your Rails app:

```ruby
OpenLoop::Client.configure do |config|
  # Healthie API Configuration
  config.healthie_api_key = ENV['HEALTHIE_API_KEY']
  config.healthie_url = ENV['HEALTHIE_URL'] # Optional, defaults based on environment
  config.healthie_authorization_shard = ENV['HEALTHIE_AUTHORIZATION_SHARD'] # Optional

  # OpenLoop API Configuration
  config.openloop_api_key = ENV['OPENLOOP_API_KEY']
  config.openloop_questionnaire_url = ENV['OPENLOOP_QUESTIONNAIRE_URL'] # Optional
  config.openloop_booking_widget_url = ENV['OPENLOOP_BOOKING_WIDGET_URL']

  # Environment (:staging or :production)
  config.environment = Rails.env.production? ? :production : :staging
end
```

### Step 2: Set Environment Variables

Create or update your `.env` file (if using dotenv gem) or `config/credentials.yml.enc`:

**Using .env file:**

```bash
# For Staging Environment
HEALTHIE_API_KEY=your_healthie_api_key_here
OPENLOOP_API_KEY=your_openloop_api_key_here
HEALTHIE_AUTHORIZATION_SHARD=your_shard_id_here
OPENLOOP_BOOKING_WIDGET_URL=https://booking-staging.openloophealth.com

# For Production Environment (comment out staging and uncomment these)
# HEALTHIE_API_KEY=your_production_healthie_api_key
# OPENLOOP_API_KEY=your_production_openloop_api_key
# HEALTHIE_AUTHORIZATION_SHARD=your_production_shard_id
# OPENLOOP_BOOKING_WIDGET_URL=https://booking.openloophealth.com
```

**Using Rails Credentials:**

```bash
# Edit credentials
EDITOR="code --wait" rails credentials:edit

# Add this content:
healthie:
  api_key: your_healthie_api_key_here
  authorization_shard: your_shard_id_here

openloop:
  api_key: your_openloop_api_key_here
  booking_widget_url: https://booking-staging.openloophealth.com
```

Then update your initializer to use credentials:

```ruby
OpenLoop::Client.configure do |config|
  config.healthie_api_key = Rails.application.credentials.dig(:healthie, :api_key)
  config.healthie_authorization_shard = Rails.application.credentials.dig(:healthie, :authorization_shard)
  config.openloop_api_key = Rails.application.credentials.dig(:openloop, :api_key)
  config.openloop_booking_widget_url = Rails.application.credentials.dig(:openloop, :booking_widget_url)
  config.environment = Rails.env.production? ? :production : :staging
end
```

### Configuration Options Explained

| Option | Required | Description | Default |
|--------|----------|-------------|---------|
| `healthie_api_key` | Yes* | Basic auth key for Healthie API | nil |
| `openloop_api_key` | Yes* | Bearer token for OpenLoop API | nil |
| `healthie_authorization_shard` | No | Shard ID for multi-tenant Healthie | nil |
| `healthie_url` | No | Healthie API endpoint | Auto-set by environment |
| `openloop_questionnaire_url` | No | OpenLoop forms API endpoint | Auto-set by environment |
| `openloop_booking_widget_url` | Yes | OpenLoop booking widget URL | nil |
| `environment` | No | :staging or :production | :staging |

*Either `healthie_api_key` OR `openloop_api_key` + `healthie_authorization_shard` is required

## GraphQL Setup

### Mount the GraphQL endpoint

In `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"

  # Optional: Mount GraphiQL for development
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
end
```

### Create the GraphQL controller

Create `app/controllers/graphql_controller.rb`:

```ruby
class GraphqlController < ApplicationController
  # Skip CSRF protection for GraphQL endpoint
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
    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end
end
```

## Usage

### GraphQL Queries

#### Get Patient by ID

```graphql
query {
  patient(id: "123456") {
    id
    firstName
    lastName
    email
    phoneNumber
    dob
    gender
    location {
      line1
      city
      state
      zip
    }
  }
}
```

#### Search Patients

```graphql
query {
  searchPatients(keywords: "john") {
    id
    name
    email
    phoneNumber
  }
}
```

#### Get Patient Appointments

```graphql
query {
  patientAppointments(userId: "123456", filter: "all") {
    id
    date
    contactType
    length
    providerName
    appointmentTypeName
  }
}
```

### GraphQL Mutations

#### Create Patient

```graphql
mutation {
  createPatient(
    firstName: "John"
    lastName: "Doe"
    email: "john.doe@example.com"
    phoneNumber: "555-123-4567"
    dietitianId: "789"
    additionalRecordIdentifier: "A1234567"
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

#### Update Patient

```graphql
mutation {
  updatePatient(
    id: "123456"
    dob: "01/01/1990"
    gender: "Male"
    height: "72"
    location: {
      line1: "123 Main St"
      city: "San Francisco"
      state: "CA"
      zip: "94102"
      country: "US"
    }
  ) {
    patient {
      id
      dob
      gender
      height
      location {
        city
        state
      }
    }
    errors
  }
}
```

#### Upload Document

```graphql
mutation {
  uploadDocument(
    fileString: "data:image/jpeg;base64,/9j/4AAQ..."
    displayName: "Lab Result 01/01/24"
    relUserId: "123456"
  ) {
    document {
      id
      ownerId
      success
    }
    errors
  }
}
```

#### Create Metric Entry (e.g., Weight)

```graphql
mutation {
  createMetricEntry(
    category: "Weight"
    type: "MetricEntry"
    metricStat: "200"
    userId: "123456"
    createdAt: "7/25/2024"
  ) {
    success
    entryId
    errors
  }
}
```

#### Create Invoice

```graphql
mutation {
  createInvoice(
    recipientId: "123456"
    price: "299"
    status: "Paid"
    servicesProvided: "Semaglutide Weekly Injection - 28 days"
  ) {
    success
    invoiceId
    errors
  }
}
```

#### Create TRT Form

```graphql
mutation {
  createTrtForm(
    patientId: "123456"
    formReferenceId: 2471727
    formData: {
      modality: "sync_visit"
      serviceType: "macro_trt"
      visitType: "Initial Visit ( visit_type_1 )"
      medicationPreference: "Testosterone Cypionate Injection + Anastrozole (as merited) ( med_trt )"
      labsWillBeOrderedThrough: "( order_vital_labs ) ( trt_initial_panel )"
      q1DoAnyOfTheFollowingApplyToYou: ["None of the above"]
    }
  ) {
    response {
      success
      message
      data
    }
    errors
  }
}
```

## Direct API Client Usage

You can also use the API clients directly without GraphQL:

```ruby
# Healthie Client
healthie = OpenLoop::Client::API::HealthieClient.new

# Create a patient
patient = healthie.create_patient({
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  phone_number: "555-1234",
  dietitian_id: "789"
})

# Get patient
patient = healthie.get_patient("123456")

# Search patients
results = healthie.search_patients("john")

# OpenLoop Client
openloop = OpenLoop::Client::API::OpenloopApiClient.new

# Create TRT form
response = openloop.create_trt_form({
  patient_id: "123456",
  formReferenceId: 2471727,
  modality: "sync_visit",
  service_type: "macro_trt"
})
```

## Architecture

The gem is organized into modular components for easy extension:

```
lib/openloop_client/
├── api/
│   ├── base_client.rb          # Base HTTP client with error handling
│   ├── healthie_client.rb      # Healthie GraphQL API wrapper
│   └── openloop_api_client.rb  # OpenLoop REST API wrapper
├── graphql/
│   ├── types/                  # GraphQL type definitions
│   ├── mutations/              # GraphQL mutations
│   ├── queries/                # GraphQL queries
│   └── schema.rb               # GraphQL schema
├── configuration.rb            # Gem configuration
└── engine.rb                   # Rails engine integration
```

## Adding New Resources

To add a new API resource:

1. Add methods to the appropriate API client (`healthie_client.rb` or `openloop_api_client.rb`)
2. Create corresponding GraphQL types in `graphql/types/`
3. Add mutations in `graphql/mutations/` or queries in `graphql/queries/`
4. Update the schema in `graphql/schema.rb`
5. Require the new files in `lib/openloop_client.rb`

Example:

```ruby
# 1. Add to API client
def get_prescriptions(patient_id)
  query = "query { prescriptions(patientId: #{patient_id}) { ... } }"
  execute_query(query)
end

# 2. Create type
class PrescriptionType < BaseObject
  field :id, ID, null: false
  field :name, String, null: true
end

# 3. Create query
class Prescriptions < BaseQuery
  type [Types::PrescriptionType], null: false
  argument :patient_id, ID, required: true

  def resolve(patient_id:)
    healthie_client.get_prescriptions(patient_id)
  end
end

# 4. Add to schema
field :prescriptions, resolver: Queries::Prescriptions
```

## Testing the Gem

### Method 1: Using Rails Console

After installing and configuring the gem, test it in your Rails console:

```bash
rails console
```

#### Test 1: Check Configuration

```ruby
# Verify configuration is loaded
OpenLoop::Client.configuration.healthie_api_key
# => "your_api_key"

OpenLoop::Client.configuration.environment
# => :staging
```

#### Test 2: Test Healthie Client - Search Patients

```ruby
# Initialize the Healthie client
healthie = OpenLoop::Client::API::HealthieClient.new

# Search for patients
result = healthie.search_patients("test")

# Check response
puts result.inspect
# Expected: {"data"=>{"users"=>[...]}}
```

#### Test 3: Test Patient Query

```ruby
# Get a specific patient (replace with real patient ID)
patient_id = "123456"
result = healthie.get_patient(patient_id)

# Print patient details
puts result.dig("data", "user", "name")
puts result.dig("data", "user", "email")
```

#### Test 4: Test GraphQL Schema

```ruby
# Execute a GraphQL query
query = <<~GRAPHQL
  query {
    searchPatients(keywords: "test") {
      id
      name
      email
    }
  }
GRAPHQL

result = OpenLoop::Client::GraphQL::Schema.execute(query)
puts result["data"]["searchPatients"]
```

#### Test 5: Create a Test Patient (Optional)

```ruby
# Get dietitian ID from configuration
config = OpenLoop::Client.configuration
dietitian_id = config.provider_id

# Create test patient
patient_data = {
  first_name: "Test",
  last_name: "User",
  email: "test+#{Time.now.to_i}@example.com",
  phone_number: "555-0000",
  dietitian_id: dietitian_id,
  additional_record_identifier: "TEST#{Time.now.to_i}"
}

result = healthie.create_patient(patient_data)
patient_id = result.dig("data", "createClient", "user", "id")
puts "Created patient with ID: #{patient_id}"

# Clean up (optional) - note: this might not delete, check Healthie API docs
```

### Method 2: Using GraphiQL Interface (Visual Testing)

**Step 1:** Start your Rails server

```bash
rails server
```

**Step 2:** Open GraphiQL in your browser

```
http://localhost:3000/graphiql
```

**Step 3:** Try these queries

#### Query 1: Search Patients

```graphql
query SearchPatients {
  searchPatients(keywords: "test") {
    id
    name
    email
    phoneNumber
  }
}
```

Click "Execute Query" button or press Ctrl+Enter

#### Query 2: Get Patient Details

```graphql
query GetPatient {
  patient(id: "YOUR_PATIENT_ID_HERE") {
    id
    firstName
    lastName
    email
    phoneNumber
    dob
    gender
    height
    weight
    location {
      line1
      city
      state
      zip
    }
  }
}
```

#### Mutation 1: Create Patient

```graphql
mutation CreatePatient {
  createPatient(
    firstName: "John"
    lastName: "Doe"
    email: "john.doe@example.com"
    phoneNumber: "555-123-4567"
    dietitianId: "YOUR_DIETITIAN_ID"
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

#### Mutation 2: Update Patient

```graphql
mutation UpdatePatient {
  updatePatient(
    id: "YOUR_PATIENT_ID"
    dob: "01/01/1990"
    gender: "Male"
    height: "72"
    location: {
      line1: "123 Main St"
      city: "San Francisco"
      state: "CA"
      zip: "94102"
      country: "US"
    }
  ) {
    patient {
      id
      dob
      gender
      height
      location {
        city
        state
      }
    }
    errors
  }
}
```

### Method 3: Create a Test Controller

Create `app/controllers/openloop_test_controller.rb`:

```ruby
class OpenloopTestController < ApplicationController
  def index
    @results = {}
  end

  def test_search
    healthie = OpenLoop::Client::API::HealthieClient.new
    @results = healthie.search_patients(params[:query] || "test")
    render json: @results
  end

  def test_patient
    healthie = OpenLoop::Client::API::HealthieClient.new
    @results = healthie.get_patient(params[:id])
    render json: @results
  end

  def test_graphql
    query = params[:query] || <<~GRAPHQL
      query {
        searchPatients(keywords: "test") {
          id
          name
          email
        }
      }
    GRAPHQL

    @results = OpenLoop::Client::GraphQL::Schema.execute(query)
    render json: @results
  end
end
```

Add routes in `config/routes.rb`:

```ruby
namespace :openloop_test do
  get :index
  get :test_search
  get :test_patient
  get :test_graphql
end
```

Visit: `http://localhost:3000/openloop_test/test_search?query=john`

### Method 4: Using cURL (API Testing)

Test the GraphQL endpoint directly:

```bash
# Test search patients
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { searchPatients(keywords: \"test\") { id name email } }"
  }'

# Test get patient
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { patient(id: \"123456\") { id name email } }"
  }'

# Test create patient mutation
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { createPatient(firstName: \"Test\", lastName: \"User\", email: \"test@example.com\", phoneNumber: \"555-0000\", dietitianId: \"789\") { patient { id firstName lastName } errors } }"
  }'
```

### Method 5: Write Integration Tests

Create `spec/integration/openloop_client_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe "OpenLoop::Client Integration", type: :request do
  before(:all) do
    # Ensure gem is configured
    OpenLoop::Client.configure do |config|
      config.healthie_api_key = ENV['HEALTHIE_API_KEY']
      config.openloop_api_key = ENV['OPENLOOP_API_KEY']
      config.environment = :staging
    end
  end

  describe "HealthieClient" do
    let(:client) { OpenLoop::Client::API::HealthieClient.new }

    it "can search patients" do
      result = client.search_patients("test")
      expect(result).to have_key("data")
      expect(result["data"]).to have_key("users")
    end

    it "can get patient details" do
      # Skip if no test patient ID
      skip unless ENV['TEST_PATIENT_ID']

      result = client.get_patient(ENV['TEST_PATIENT_ID'])
      expect(result).to have_key("data")
      expect(result["data"]).to have_key("user")
    end
  end

  describe "GraphQL Schema" do
    it "can execute search query" do
      query = <<~GRAPHQL
        query {
          searchPatients(keywords: "test") {
            id
            name
          }
        }
      GRAPHQL

      result = OpenLoop::Client::GraphQL::Schema.execute(query)
      expect(result).to have_key("data")
      expect(result["data"]).to have_key("searchPatients")
    end
  end

  describe "GraphQL Endpoint" do
    it "responds to GraphQL queries" do
      post "/graphql", params: {
        query: "query { searchPatients(keywords: \"test\") { id name } }"
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key("data")
    end
  end
end
```

Run tests:

```bash
bundle exec rspec spec/integration/openloop_client_spec.rb
```

### Expected Results

#### Successful Response Example:

```json
{
  "data": {
    "searchPatients": [
      {
        "id": "123456",
        "name": "John Doe",
        "email": "john.doe@example.com",
        "phoneNumber": "555-123-4567"
      }
    ]
  }
}
```

#### Error Response Example:

```json
{
  "errors": [
    {
      "message": "Unauthorized: Check your API credentials"
    }
  ]
}
```

### Troubleshooting Tests

| Issue | Solution |
|-------|----------|
| "Unauthorized" error | Check API keys in `.env` or credentials |
| "Connection refused" | Verify API URLs are correct for your environment |
| Empty results | Use real patient data or create test patients first |
| GraphQL errors | Check query syntax in GraphiQL first |
| Gem not loading | Run `bundle install` and restart Rails server |

### Quick Verification Checklist

- [ ] Gem installed: `bundle list | grep openloop-client`
- [ ] Configuration loaded: `rails runner "puts OpenLoop::Client.configuration.inspect"`
- [ ] GraphQL endpoint mounted: `rails routes | grep graphql`
- [ ] GraphiQL accessible: Visit `/graphiql` in browser
- [ ] API credentials valid: Test in Rails console
- [ ] Can search patients: Test via GraphiQL or console
- [ ] Can query patient: Test with real patient ID
- [ ] Mutations work: Test create/update operations

## Development

After checking out the repo, run:

```bash
bin/setup
```

Interactive console:

```bash
bin/console
```

Build the gem:

```bash
gem build openloop-client.gemspec
```

Install locally:

```bash
gem install openloop-client-0.1.0.gem
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/openloop/openloop-client.

## License

The gem is available as open source under the terms of the MIT License.
