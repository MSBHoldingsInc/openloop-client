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

# Step 3: Get User Locations (optional - to update existing location)
# Fetch existing location ID if patient already has a location
locations_response = healthie.get_user_locations(patient_id)
location_id = locations_response.dig('data', 'locations', 0, 'id')

# Step 4: Update Patient with additional information
update_data = {
  id: patient_id,
  dob: "01/01/1990",
  gender: "Male",
  height: "72",
  location: {
    id: location_id, # Include location ID when updating existing location
    line1: "123 Main St",
    city: "San Francisco",
    state: "CA",
    zip: "94102",
    country: "US"
  }.compact
}

healthie.update_patient(update_data)

# Step 5: Create TRT Initial Intake Form
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

# Step 6: Upload Lab Results Document
file_base64 = "data:image/jpeg;base64,/9j/4AAQ..." # Your base64 encoded file
document_input = {
  file_string: file_base64,
  display_name: "Lab Result 01/01/24",
  description: "Patient lab results",
  rel_user_id: patient_id
}

healthie.upload_document(document_input)

# Step 7: Create Metric Entry (Weight)
metric_data = {
  category: "Weight",
  type: "MetricEntry",
  metric_stat: "200",
  user_id: patient_id,
  created_at: "1/1/2024"
}

healthie.create_metric_entry(metric_data)

# Step 8: Create Invoice
invoice_data = {
  recipient_id: patient_id,
  price: "299",
  status: "Paid",
  services_provided: "Semaglutide Weekly Injection - 28 days"
}

healthie.create_invoice(invoice_data)

# Step 9: Get Patient Details
patient = healthie.get_patient(patient_id)
puts "Patient: #{patient.dig('data', 'user', 'name')}"

# Step 10: Get Patient Appointments
appointments = healthie.get_patient_appointments(patient_id, "all")
puts "Appointments: #{appointments.dig('data', 'appointments').count}"

# Step 11: Get Specific Appointment Details
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

# Step 12: Get Lab Facilities (At-Home vs Walk-In)
lab_facilities = openloop.get_lab_facilities(zip_code: "50309", radius: 50)
puts "Lab Facilities: #{lab_facilities}"

# Step 13: Get Lab Test Results (requires order_id from Vital)
junction = OpenLoop::Client::API::JunctionApiClient.new
order_id = "550e8400-e29b-41d4-a716-446655440000"
lab_results = junction.get_lab_results(order_id: order_id)
puts "Lab Results Metadata: #{lab_results['metadata']}"
puts "Biomarker Results: #{lab_results['results']}"

# Step 14: Get Patient Service Center (PSC) Information
# Get PSC locations for lab order with default 50 mile radius
psc_info = junction.get_order_psc_info(order_id: order_id)
puts "Lab Provider: #{psc_info['slug']}"
puts "Available PSC Locations: #{psc_info['patient_service_centers'].count}"

# Get PSC locations with custom radius
psc_info = junction.get_order_psc_info(order_id: order_id, radius: 10)
psc_info['patient_service_centers'].each do |psc|
  puts "Location: #{psc.dig('metadata', 'name')}"
  puts "Address: #{psc.dig('metadata', 'first_line')}, #{psc.dig('metadata', 'city')}, #{psc.dig('metadata', 'state')}"
  puts "Distance: #{psc['distance']} miles"
  puts "Hours: #{psc.dig('metadata', 'hours')}"
end
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

### Response Structure

The `get_appointment` method returns the appointment data from the Healthie API:

```ruby
{
  "data" => {
    "appointment" => {
      "id" => "2037619",
      "date" => "2024-01-15T10:00:00Z",
      "length" => "30",
      "pm_status" => "Scheduled",
      "user_id" => "123456",
      "timezone_abbr" => "PST",
      "external_videochat_url" => "https://example.com/videochat",
      "provider" => {
        "id" => "789",
        "name" => "Dr. Smith",
        "email" => "doctor@example.com",
        "npi" => "1234567890",
        "organization" => {
          "id" => "101",
          "name" => "Health Clinic"
        }
      },
      "appointment_type" => {
        "id" => "456"
      },
      "requested_payment" => {
        "id" => "999"
      },
      "user" => {
        "id" => "123456",
        "first_name" => "John",
        "last_name" => "Doe",
        "full_name" => "John Doe",
        "email" => "john.doe@example.com"
      }
    }
  }
}
```

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
# => "https://express.patientcare.openloophealth.com/book-appointment?appointmentTypeId=...&providerId=..."

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
# => "https://express.patientcare.openloophealth.com/book-appointment?appointmentTypeId=349681&providerId=3483153&firstName=John&lastName=Doe&email=john@example.com&phoneNumber=5551234567&state=CA&zip=90001&redirectUrl=https://start.rugiet.com"

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

## Form Answer Group API

### Get Form Answer Group

```ruby
# Initialize Healthie client
healthie = OpenLoop::Client::API::HealthieClient.new

# Get form answer group by ID
form_answer_group_id = "1240332"
response = healthie.get_form_answer_group(form_answer_group_id)

# Access form answer group data
form_data = response.dig("data", "formAnswerGroup")
puts "Form ID: #{form_data['id']}"
puts "User ID: #{form_data['user_id']}"
puts "Finished: #{form_data['finished']}"
puts "Created At: #{form_data['record_created_at']}"
puts "Updated At: #{form_data['updated_at']}"

# Access custom module form
custom_form = form_data['custom_module_form']
puts "\nCustom Module Form ID: #{custom_form['id']}" if custom_form

# Access form answers
puts "\nForm Answers (#{form_data['form_answers'].count} total):"
form_data['form_answers'].each do |answer|
  next if answer['answer'].nil? || answer['answer'].empty?
  puts "  #{answer['label']}: #{answer['answer']}"
end

# Access appointment information (if available)
if form_data['appointment']
  appointment = form_data['appointment']
  puts "\nAppointment:"
  puts "  ID: #{appointment['id']}"
  puts "  Provider: #{appointment['provider_name']}"
end

# Access user information
user = form_data['user']
if user
  puts "\nUser:"
  puts "  ID: #{user['id']}"
  puts "  Email: #{user['email']}"
end

# Access current summary (if available)
if form_data['current_summary']
  summary = form_data['current_summary']
  puts "\nCurrent Summary:"
  puts "  ID: #{summary['id']}"
  puts "  Summary: #{summary['summary']}"
end

```

### Example Response

```ruby
{
  "data" => {
    "formAnswerGroup" => {
      "id" => "1240332",
      "user_id" => "3733250",
      "finished" => true,
      "record_created_at" => "2026-01-13 14:56:16 -0600",
      "updated_at" => "2026-01-13 15:00:24 -0600",
      "metadata" => nil,
      "custom_module_form" => {"id" => "2190742"},
      "form_answers" => [
        {"label" => "Hormone Type", "answer" => "TRT"},
        {"label" => "Note Type", "answer" => "1. Visit Charting + Prescription Note"},
        {"label" => "Visit Type", "answer" => "Initial Visit ( visit_type_1 )"},
        {"label" => "Name of Patient", "answer" => "John Doe"},
        {"label" => "Date of Birth", "answer" => "1988-01-01"},
        # ... more form answers
      ],
      "locked_at" => "2026-01-14 13:54:19 -0600",
      "locked_by" => {
        "full_name" => "John Doe",
        "profession" => nil
      },
      "appointment" => nil,
      "user" => {
        "id" => "3733250",
        "email" => "john.doe@example.com"
      },
      "current_summary" => nil,
      "individual_client_notes" => []
    }
  }
}
```

## User Locations API

### Get User Locations

Retrieve all location addresses associated with a patient in Healthie. This is useful when updating a patient's address, as you need to provide the existing location ID.

```ruby
# Initialize Healthie client
healthie = OpenLoop::Client::API::HealthieClient.new

# Get all locations for a user
patient_id = "123456"
response = healthie.get_user_locations(patient_id)

# Access location data
locations = response.dig("data", "locations")
puts "User has #{locations.count} location(s)"

# Get first location details
if locations&.any?
  location = locations.first
  puts "\nLocation ID: #{location['id']}"
  puts "Address Line 1: #{location['line1']}"
  puts "Address Line 2: #{location['line2']}" if location['line2']
  puts "City: #{location['city']}"
  puts "State: #{location['state']}"
  puts "Zip: #{location['zip']}"
  puts "Country: #{location['country']}"
end
```

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
