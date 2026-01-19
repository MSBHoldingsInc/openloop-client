# OpenLoop::Client - Usage Examples

## Configuration Example

```ruby
# config/initializers/openloop_client.rb
OpenLoop::Client.configure do |config|
  config.healthie_api_key = ENV['HEALTHIE_API_KEY'] # optional
  config.openloop_api_key = ENV['OPENLOOP_API_KEY']
  config.healthie_authorization_shard = ENV['HEALTHIE_AUTHORIZATION_SHARD']
  config.vital_api_key = ENV['VITAL_API_KEY']
  config.environment = :staging
end
```

## Complete Patient Workflow Example

```ruby
# Initialize clients
healthie = OpenLoop::Client::API::HealthieClient.new
openloop = OpenLoop::Client::API::OpenloopApiClient.new
config = OpenLoop::Client.configuration

# Step 1: Get provider_id from configuration
# The provider_id is automatically set based on environment:
# - Staging: 3483153
# - Production: 9584181
dietitian_id = config.provider_id

# Step 2: Create Patient
patient_data = {
  first_name: "John",
  last_name: "Doe",
  email: "john.doe@example.com",
  phone_number: "555-123-4567",
  dietitian_id: dietitian_id,
  additional_record_identifier: "A1234567",
  skipped_email: false,
  dont_send_welcome: false
}

patient_response = healthie.create_patient(patient_data)
patient_id = patient_response.dig("data", "createClient", "user", "id")

# Step 3: Update Patient with additional information
update_data = {
  id: patient_id,
  dob: "01/01/1990",
  gender: "Male",
  height: "72",
  location: {
    line1: "123 Main St",
    city: "San Francisco",
    state: "CA",
    zip: "94102",
    country: "US"
  }
}

healthie.update_patient(update_data)

# Step 4: Create TRT Initial Intake Form
form_data = {
  patient_id: patient_id,
  formReferenceId: 2471727, # Production form ID
  driver_license: "",
  driver_license_state: "",
  modality: "sync_visit",
  service_type: "macro_trt",
  visit_type: "Initial Visit ( visit_type_1 )",
  medication_preference: "Testosterone Cypionate Injection + Anastrozole (as merited) ( med_trt )",
  labs_will_be_ordered_through: "( order_vital_labs ) ( trt_initial_panel )",
  q1_do_any_of_the_following_apply_to_you: ["None of the above"],
  q3_do_any_of_the_following_conditions_or_situations_apply_to_you: ["Poor sleep"],
  q4_do_any_of_the_following_conditions_or_situations_apply_to_you: ["None of the above"],
  q5_do_any_of_the_following_conditions_or_situations_apply_to_you: ["Low levels of testosterone on prior labs"],
  q8_current_medications_updates: ["None"],
  "9_medication_and_allergy_history": ["None of the above"]
}

form_response = openloop.create_trt_form(form_data)

# Step 5: Upload Lab Results Document
file_base64 = "data:image/jpeg;base64,/9j/4AAQ..." # Your base64 encoded file
document_data = {
  file_string: file_base64,
  display_name: "Lab Result 01/01/24",
  rel_user_id: patient_id
}

healthie.upload_document(document_data)

# Step 6: Create Metric Entry (Weight)
metric_data = {
  category: "Weight",
  type: "MetricEntry",
  metric_stat: "200",
  user_id: patient_id,
  created_at: "1/1/2024"
}

healthie.create_metric_entry(metric_data)

# Step 7: Create Invoice
invoice_data = {
  recipient_id: patient_id,
  price: "299",
  status: "Paid",
  services_provided: "Semaglutide Weekly Injection - 28 days"
}

healthie.create_invoice(invoice_data)

# Step 8: Get Patient Details
patient = healthie.get_patient(patient_id)
puts "Patient: #{patient.dig('data', 'user', 'name')}"

# Step 9: Get Patient Appointments
appointments = healthie.get_patient_appointments(patient_id, "all")
puts "Appointments: #{appointments.dig('data', 'appointments').count}"

# Step 10: Get Specific Appointment Details
if appointments.dig('data', 'appointments')&.any?
  appointment_id = appointments.dig('data', 'appointments', 0, 'id')
  appointment_details = healthie.get_appointment(appointment_id)
  appointment_data = appointment_details.dig('data', 'appointment')
  puts "Appointment Date: #{appointment_data['date']}"
  puts "Provider: #{appointment_data.dig('provider', 'name')}"
  puts "Patient: #{appointment_data.dig('user', 'full_name')}"
  puts "Length: #{appointment_data['length']} minutes"
  puts "PM Status: #{appointment_data['pm_status']}"
  puts "Video URL: #{appointment_data['external_videochat_url']}" if appointment_data['external_videochat_url']

  # Cancel appointment if needed
  # cancel_result = healthie.cancel_appointment(appointment_id)
  # puts "Cancelled: #{cancel_result.dig('data', 'updateAppointment', 'appointment', 'pm_status')}"
end

# Step 11: Get Lab Facilities (At-Home vs Walk-In)
lab_facilities = openloop.get_lab_facilities(zip_code: "50309", radius: 50)
puts "Lab Facilities: #{lab_facilities}"

# Step 12: Get Lab Test Results (requires order_id from Vital)
junction = OpenLoop::Client::API::JunctionApiClient.new
order_id = "550e8400-e29b-41d4-a716-446655440000"
lab_results = junction.get_lab_results(order_id: order_id)
puts "Lab Results Metadata: #{lab_results['metadata']}"
puts "Biomarker Results: #{lab_results['results']}"
```

## Appointment Details API

### Get Specific Appointment

```ruby
# Initialize Healthie client
healthie = OpenLoop::Client::API::HealthieClient.new

# Get specific appointment details
appointment_id = "123456"
appointment = healthie.get_appointment(appointment_id)

# Access appointment data
appointment_data = appointment.dig("data", "appointment")
puts "Appointment ID: #{appointment_data['id']}"
puts "Date: #{appointment_data['date']}"
puts "Length: #{appointment_data['length']} minutes"
puts "Timezone: #{appointment_data['timezone_abbr']}"
puts "PM Status: #{appointment_data['pm_status']}"
puts "User ID: #{appointment_data['user_id']}"
puts "Video Chat URL: #{appointment_data['external_videochat_url']}"

# Access provider information
provider = appointment_data['provider']
puts "\nProvider:"
puts "  Name: #{provider['name']}"
puts "  Email: #{provider['email']}"
puts "  NPI: #{provider['npi']}"
puts "  Organization: #{provider.dig('organization', 'name')}"

# Access user/patient information
user = appointment_data['user']
if user
  puts "\nPatient:"
  puts "  Name: #{user['full_name']}"
  puts "  Email: #{user['email']}"
end
```

### Cancel Appointment

```ruby
# Initialize Healthie client
healthie = OpenLoop::Client::API::HealthieClient.new

# Cancel an appointment
appointment_id = "2207949"
result = healthie.cancel_appointment(appointment_id)

# Check result
if result.dig("data", "updateAppointment", "appointment")
  appointment = result.dig("data", "updateAppointment", "appointment")
  puts "Appointment #{appointment['id']} cancelled successfully"
  puts "PM Status: #{appointment['pm_status']}"
else
  errors = result.dig("data", "updateAppointment", "messages")
  puts "Error cancelling appointment: #{errors}"
end
```

## Booking Widget URL

### Generate Booking Widget URL

```ruby
# Initialize OpenLoop API client
openloop = OpenLoop::Client::API::OpenloopApiClient.new

# Generate booking URL for TRT initial visit (default)
url = openloop.booking_widget_url
puts url
# => "https://booking-staging.openloophealth.com?appointmentTypeId=...&providerId=..."

# Generate booking URL with patient information
url = openloop.booking_widget_url(
  therapy_type: 'trt',
  visit_type: 'initial',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phoneNumber: '5551234567',
  state: 'CA',
  zip: '90001',
  redirectUrl: 'https://start.rugiet.com'
)
puts url
# => "https://express.care-staging.openloophealth.com/book-appointment?appointmentTypeId=349681&providerId=3483153&firstName=John&lastName=Doe&email=john@example.com&phoneNumber=5551234567&state=CA&zip=90001&redirectUrl=https://start.rugiet.com"

# Generate URL for TRT refill visit
url = openloop.booking_widget_url(
  therapy_type: 'trt',
  visit_type: 'refill',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com'
)

# Generate URL for Enclomiphene initial visit
url = openloop.booking_widget_url(
  therapy_type: 'enclomiphene',
  visit_type: 'initial',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com'
)

# Generate URL for Enclomiphene refill visit
url = openloop.booking_widget_url(
  therapy_type: 'enclomiphene',
  visit_type: 'refill',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com'
)
```

### Available Options

**therapy_type**: (String, default: 'trt')
- `'trt'` - Testosterone Replacement Therapy
- `'enclomiphene'` - Enclomiphene therapy

**visit_type**: (String, default: 'initial')
- `'initial'` - Initial visit
- `'refill'` - Refill/follow-up visit

**Additional Parameters** (all optional, commonly used):
- `firstName` - Patient first name
- `lastName` - Patient last name
- `email` - Patient email address
- `phoneNumber` - Patient phone number (e.g., '5551234567')
- `state` - Patient state (e.g., 'CA')
- `zip` - Patient zip code (e.g., '90001')
- `redirectUrl` - URL to redirect to after booking (e.g., 'https://start.rugiet.com')
- `headless` - (Boolean, default: false) Determines if the widget should run in headless mode

## Lab Facilities API

### Get Lab Facilities by Zip Code

```ruby
# Initialize OpenLoop API client
openloop = OpenLoop::Client::API::OpenloopApiClient.new

# Get lab facilities within 50 miles of zip code
response = openloop.get_lab_facilities(zip_code: "50309", radius: 50)

# Default radius is 50 miles if not specified
response = openloop.get_lab_facilities(zip_code: "50309")

# Response will contain available lab facilities
puts response
```

## Lab Test Results API

### Get Lab Test Results from Vital

```ruby
# Initialize Junction API client
junction = OpenLoop::Client::API::JunctionApiClient.new

# Get lab test results for a specific order
# Note: Requires vital_api_key to be configured
order_id = "550e8400-e29b-41d4-a716-446655440000" # UUID format
results = junction.get_lab_results(order_id: order_id)

# Access metadata (patient info)
metadata = results["metadata"]
puts "Patient: #{metadata['patient']}"
puts "Age: #{metadata['age']}"
puts "Report Date: #{metadata['date_reported']}"

# Access individual biomarker results
results["results"].each do |biomarker|
  puts "\n#{biomarker['name']}:"
  puts "  Value: #{biomarker['value']} #{biomarker['unit']}"
  puts "  Reference Range: #{biomarker['min_range_value']} - #{biomarker['max_range_value']}"
  puts "  Status: #{biomarker['is_above_max_range'] ? 'High' : biomarker['is_below_min_range'] ? 'Low' : 'Normal'}"
end

```

## Error Handling Examples

```ruby
begin
  healthie = OpenLoop::Client::API::HealthieClient.new
  patient = healthie.create_patient(patient_data)
rescue OpenLoop::Client::API::BaseClient::APIError => e
  puts "API Error: #{e.message}"
  puts "Response Code: #{e.response.code}" if e.response
  puts "Response Body: #{e.response.body}" if e.response
end
```

## Environment-Specific Configuration

```ruby
# config/environments/production.rb
OpenLoop::Client.configure do |config|
  config.environment = :production
  config.healthie_api_key = ENV['HEALTHIE_PROD_API_KEY']
  config.openloop_api_key = ENV['OPENLOOP_PROD_API_KEY']
  config.vital_api_key = ENV['VITAL_PROD_API_KEY']
end

# config/environments/staging.rb
OpenLoop::Client.configure do |config|
  config.environment = :staging
  config.healthie_api_key = ENV['HEALTHIE_STAGING_API_KEY']
  config.openloop_api_key = ENV['OPENLOOP_STAGING_API_KEY']
  config.vital_api_key = ENV['VITAL_STAGING_API_KEY']
end
```
