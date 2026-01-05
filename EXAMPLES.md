# OpenLoop::Client - Usage Examples

## Configuration Example

```ruby
config/initializers/openloop_client.rb
OpenLoop::Client.configure do |config|
  config.healthie_api_key = ENV['HEALTHIE_API_KEY'] # optional
  config.openloop_api_key = ENV['OPENLOOP_API_KEY']
  config.healthie_authorization_shard = ENV['HEALTHIE_AUTHORIZATION_SHARD']
  config.openloop_booking_widget_url = ENV['OPENLOOP_BOOKING_WIDGET_URL'] # optional
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

# Step 10: Get Lab Facilities (At-Home vs Walk-In)
lab_facilities = openloop.get_lab_facilities(zip_code: "50309", radius: 50)
puts "Lab Facilities: #{lab_facilities}"
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

## GraphQL Query Examples

### 1. Get Patient with All Details

```graphql
query GetPatientDetails($patientId: ID!) {
  patient(id: $patientId) {
    id
    firstName
    lastName
    name
    email
    phoneNumber
    dob
    gender
    height
    weight
    age
    timezone
    dietitianId
    additionalRecordIdentifier
    bmiPercentile
    nextApptDate
    createdAt
    updatedAt
    location {
      line1
      line2
      city
      state
      zip
      country
    }
  }
}

# Variables
{
  "patientId": "123456"
}
```

### 2. Search and Create Patient Flow

```graphql
# First, search if patient exists
query SearchPatient($keywords: String!) {
  searchPatients(keywords: $keywords) {
    id
    name
    email
    phoneNumber
  }
}

# If not found, create patient
mutation CreateNewPatient($input: CreatePatientInput!) {
  createPatient(
    firstName: $input.firstName
    lastName: $input.lastName
    email: $input.email
    phoneNumber: $input.phoneNumber
    dietitianId: $input.dietitianId
    additionalRecordIdentifier: $input.additionalRecordIdentifier
  ) {
    patient {
      id
      firstName
      lastName
      email
      phoneNumber
    }
    errors
  }
}

# Variables
{
  "keywords": "john.doe@example.com",
  "input": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phoneNumber": "555-123-4567",
    "dietitianId": "789",
    "additionalRecordIdentifier": "A1234567"
  }
}
```

### 3. Complete Patient Update

```graphql
mutation UpdatePatientComplete($patientId: ID!, $updateData: UpdatePatientInput!) {
  updatePatient(
    id: $patientId
    dob: $updateData.dob
    gender: $updateData.gender
    height: $updateData.height
    additionalRecordIdentifier: $updateData.additionalRecordIdentifier
    location: $updateData.location
  ) {
    patient {
      id
      dob
      gender
      height
      additionalRecordIdentifier
      location {
        line1
        line2
        city
        state
        zip
        country
      }
    }
    errors
  }
}

# Variables
{
  "patientId": "123456",
  "updateData": {
    "dob": "01/01/1990",
    "gender": "Male",
    "height": "72",
    "additionalRecordIdentifier": "A1234567",
    "location": {
      "line1": "123 Main St",
      "line2": "Apt 4B",
      "city": "San Francisco",
      "state": "CA",
      "zip": "94102",
      "country": "US"
    }
  }
}
```

### 4. TRT Initial Intake Form Submission

```graphql
mutation SubmitTRTInitialIntake($patientId: ID!, $formData: JSON!) {
  createTrtForm(
    patientId: $patientId
    formReferenceId: 2471727
    formData: $formData
  ) {
    response {
      success
      message
      data
    }
    errors
  }
}

# Variables
{
  "patientId": "123456",
  "formData": {
    "driver_license": "",
    "driver_license_state": "",
    "modality": "sync_visit",
    "service_type": "macro_trt",
    "visit_type": "Initial Visit ( visit_type_1 )",
    "medication_preference": "Testosterone Cypionate Injection + Anastrozole (as merited) ( med_trt )",
    "labs_will_be_ordered_through": "( order_vital_labs ) ( trt_initial_panel )",
    "q1_do_any_of_the_following_apply_to_you": ["None of the above"],
    "q3_do_any_of_the_following_conditions_or_situations_apply_to_you": ["Poor sleep"],
    "q4_do_any_of_the_following_conditions_or_situations_apply_to_you": ["None of the above"],
    "q5_do_any_of_the_following_conditions_or_situations_apply_to_you": ["Low levels of testosterone on prior labs"],
    "q6_if_you_have_previously_been_or_currently_are_on_testosterone_replacement_theraphy": ["Cream, Gel"],
    "q7_name_strenght_date_of_the_last_dose_of_testosterone_or_related_replacement_therapy": ["3.5ml of cream, applied daily. Last taken 01/01/1999"],
    "q8_current_medications_updates": ["None"],
    "9_medication_and_allergy_history": ["None of the above"]
  }
}
```

### 5. TRT Refill Form Submission

```graphql
mutation SubmitTRTRefill($patientId: ID!, $formData: JSON!) {
  createTrtForm(
    patientId: $patientId
    formReferenceId: 2471728
    formData: $formData
  ) {
    response {
      success
      message
      data
    }
    errors
  }
}

# Variables
{
  "patientId": "123456",
  "formData": {
    "driver_license": "",
    "driver_license_state": "",
    "modality": "sync_visit",
    "service_type": "macro_trt",
    "visit_type": "Follow Up ( visit_type_2 ) ( first_month_review )",
    "medication_preference": "Testosterone Cypionate Injection + Anastrozole (as merited) ( med_trt )",
    "labs_will_be_ordered_through": "( order_vital_labs ) ( trt_month_1_check_in_panel )",
    "q1_since_last_visit_are_you_taking_medication_as_scheduled": ["Yes"],
    "q4_any_changes_to_medications_or_allergies": ["No changes"],
    "q5_how_have_your_symptoms_changed_since_last_visit": ["improved"],
    "q6_5a_how_have_your_symptoms_changed_since_last_visit_details": ["I have been able to sleep and i am not as tired."],
    "q7_since_last_visit_do_any_of_the_following_apply_to_you": ["None of the above"],
    "q8_since_last_visit_have_you_experienced_any_of_the_following_side_effects": ["None of the above"],
    "9_are_you_concerned_about_or_experiencing_testicular_shrinkage_potentially_as_a_result_of_using_testosterone_replacement_therapy": ["No"]
  }
}
```

### 6. Document Upload with Metric Entry

```graphql
# Upload document
mutation UploadLabResults($fileString: String!, $patientId: ID!) {
  uploadDocument(
    fileString: $fileString
    displayName: "Lab Result 01/15/24"
    relUserId: $patientId
  ) {
    document {
      id
      ownerId
      success
    }
    errors
  }
}

# Record weight metric
mutation RecordWeight($patientId: ID!, $weight: String!) {
  createMetricEntry(
    category: "Weight"
    type: "MetricEntry"
    metricStat: $weight
    userId: $patientId
    createdAt: "1/15/2024"
  ) {
    success
    entryId
    errors
  }
}

# Variables
{
  "patientId": "123456",
  "fileString": "data:image/jpeg;base64,/9j/4AAQ...",
  "weight": "195"
}
```

### 7. Create Invoice for Services

```graphql
mutation CreateServiceInvoice($patientId: ID!, $serviceDetails: InvoiceInput!) {
  createInvoice(
    recipientId: $patientId
    price: $serviceDetails.price
    status: $serviceDetails.status
    servicesProvided: $serviceDetails.servicesProvided
    notes: $serviceDetails.notes
  ) {
    success
    invoiceId
    errors
  }
}

# Variables
{
  "patientId": "123456",
  "serviceDetails": {
    "price": "299",
    "status": "Paid",
    "servicesProvided": "Semaglutide Weekly Injection - 28 days",
    "notes": "First month payment"
  }
}
```

### 8. Get Patient Appointments History

```graphql
query GetPatientHistory($patientId: ID!) {
  patient(id: $patientId) {
    id
    name
    email
    nextApptDate
  }

  patientAppointments(userId: $patientId, filter: "all") {
    id
    date
    contactType
    length
    location
    providerName
    appointmentTypeName
  }
}

# Variables
{
  "patientId": "123456"
}
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
end

# config/environments/staging.rb
OpenLoop::Client.configure do |config|
  config.environment = :staging
  config.healthie_api_key = ENV['HEALTHIE_STAGING_API_KEY']
  config.openloop_api_key = ENV['OPENLOOP_STAGING_API_KEY']
end
```
