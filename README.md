# OpenLoop::Client

A Rails gem that provides a GraphQL interface to OpenLoop Health and Healthie APIs for patient management, forms, and appointments. Built with scalability in mind, making it easy to add new resources and endpoints.

## Features

- GraphQL API wrapper for OpenLoop Health and Healthie APIs
- Patient management (CRUD operations)
- Document uploads
- Metric entries (weight, etc.)
- Invoice creation
- TRT form submissions
- Appointment management (list appointments, get appointment details, cancel appointments)
- Lab test results retrieval (via Vital API)
- GraphiQL interface for API exploration
- HTTParty-based REST client
- Configurable for staging and production environments
- Modular architecture for easy extension

## Installation

### Option 1: Install from local path (Development)

Add this line to your Rails application's Gemfile:

```ruby
gem 'openloop-client', path: '../openloop-client', require: 'openloop_client'
```

Then execute:

```bash
bundle install
```

### Option 2: Install from git (Once pushed to repository)

```ruby
gem 'openloop-client', git: 'https://github.com/MSBHoldingsInc/openloop-client', require: 'openloop_client'
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
  config.healthie_authorization_shard = ENV['HEALTHIE_AUTHORIZATION_SHARD'] # Optional

  # OpenLoop API Configuration
  config.openloop_api_key = ENV['OPENLOOP_API_KEY']

  # Vital API Configuration (for lab results)
  config.vital_api_key = ENV['VITAL_API_KEY']

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
VITAL_API_KEY=your_vital_api_key_here

# For Production Environment (comment out staging and uncomment these)
# HEALTHIE_API_KEY=your_production_healthie_api_key
# OPENLOOP_API_KEY=your_production_openloop_api_key
# HEALTHIE_AUTHORIZATION_SHARD=your_production_shard_id
# OPENLOOP_BOOKING_WIDGET_URL=https://booking.openloophealth.com
# VITAL_API_KEY=your_production_vital_api_key
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

vital:
  api_key: your_vital_api_key_here
```

Then update your initializer to use credentials:

```ruby
OpenLoop::Client.configure do |config|
  config.healthie_api_key = Rails.application.credentials.dig(:healthie, :api_key)
  config.healthie_authorization_shard = Rails.application.credentials.dig(:healthie, :authorization_shard)
  config.openloop_api_key = Rails.application.credentials.dig(:openloop, :api_key)
  config.vital_api_key = Rails.application.credentials.dig(:vital, :api_key)
  config.environment = Rails.env.production? ? :production : :staging
end
```

### Configuration Options Explained

| Option | Required | Description | Default |
|--------|----------|-------------|---------|
| `healthie_api_key` | Yes* | Basic auth key for Healthie API | nil |
| `openloop_api_key` | Yes* | Bearer token for OpenLoop API | nil |
| `healthie_authorization_shard` | No | Shard ID for multi-tenant Healthie | nil |
| `vital_api_key` | No | API key for Vital lab results | nil |
| `environment` | No | :staging or :production | :staging |

*Either `healthie_api_key` OR `openloop_api_key` + `healthie_authorization_shard` is required

**Note:** The following values are automatically configured based on environment and cannot be overridden:
- **Healthie URL**: `api.gethealthie.com` (prod) / `staging-api.gethealthie.com` (staging)
- **Vital API URL**: `api.tryvital.io/v3` (prod) / `api.sandbox.tryvital.io/v3` (staging)
- **OpenLoop Questionnaire URL**: Auto-configured per environment
- **Booking Widget URL**: Auto-configured per environment
- **Org ID, Provider ID, Form IDs, Appointment Type IDs**: Auto-configured per environment

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
  phone_number: "555-123-4567",
  dietitian_id: "789"
})

# Get patient
patient = healthie.get_patient("123456")

# Search patients
results = healthie.search_patients("john")

# Get appointment details
appointment = healthie.get_appointment("2037619")
appointment_data = appointment.dig("data", "appointment")
puts "Appointment Date: #{appointment_data['date']}"
puts "Provider: #{appointment_data.dig('provider', 'name')}"
puts "PM Status: #{appointment_data['pm_status']}"

# Cancel appointment
result = healthie.cancel_appointment("2037619")
puts result.dig("data", "updateAppointment", "appointment", "pm_status")
# => "Cancelled"

# OpenLoop Client
openloop = OpenLoop::Client::API::OpenloopApiClient.new

# Create TRT form
response = openloop.create_trt_form({
  patient_id: "123456",
  formReferenceId: 2471727,
  modality: "sync_visit",
  service_type: "macro_trt"
})

# Junction Client (for Vital lab results)
junction = OpenLoop::Client::API::JunctionApiClient.new

# Get lab test results (requires Vital API key)
order_id = "550e8400-e29b-41d4-a716-446655440000"
results = junction.get_lab_results(order_id: order_id)
puts results["metadata"]
puts results["results"]
```

## Architecture

The gem is organized into modular components for easy extension:

```
lib/openloop_client/
├── api/
│   ├── base_client.rb          # Base HTTP client with error handling
│   ├── healthie_client.rb      # Healthie GraphQL API wrapper
│   ├── openloop_api_client.rb  # OpenLoop REST API wrapper
│   └── junction_api_client.rb  # Junction/Vital API wrapper (lab results)
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

### Using Rails Console

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

#### Test 5: Create a Test Patient

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

```

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

Bug reports and pull requests are welcome on GitHub at https://github.com/MSBHoldingsInc/openloop-client
