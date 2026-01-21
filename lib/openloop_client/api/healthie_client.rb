# frozen_string_literal: true

module OpenLoop
  module Client
    module API
      # Client for interacting with the Healthie GraphQL API.
      #
      # The HealthieClient provides methods for patient management, document
      # uploads, metric entries, invoices, and appointment operations. It
      # communicates with Healthie's GraphQL endpoint and handles authentication
      # automatically based on the configured credentials.
      #
      # @example Basic usage
      #   healthie = OpenLoop::Client::API::HealthieClient.new
      #
      #   # Get a patient
      #   patient = healthie.get_patient("123456")
      #   puts patient.dig("data", "user", "name")
      #
      #   # Search for patients
      #   results = healthie.search_patients("john")
      #
      # @example Creating a patient
      #   healthie = OpenLoop::Client::API::HealthieClient.new
      #   response = healthie.create_patient({
      #     first_name: "John",
      #     last_name: "Doe",
      #     email: "john@example.com",
      #     dietitian_id: config.provider_id
      #   })
      #   patient_id = response.dig("data", "createClient", "user", "id")
      #
      # @see OpenLoop::Client::Configuration Configuration for API credentials
      class HealthieClient < BaseClient
        # Creates a new HealthieClient instance.
        #
        # @return [HealthieClient] a new client instance
        # @raise [RuntimeError] if configuration is not set
        def initialize
          @config = OpenLoop::Client.configuration
        end

        # Executes a GraphQL query against the Healthie API.
        #
        # @param query [String] the GraphQL query or mutation string
        # @param variables [Hash] variables to pass to the query
        # @return [Hash] the parsed JSON response from Healthie
        # @raise [APIError] if the request fails or returns an error status
        #
        # @example Execute a custom query
        #   response = client.execute_query(
        #     'query { users(keywords: $keywords) { id name } }',
        #     { keywords: "test" }
        #   )
        def execute_query(query, variables = {})
          response = self.class.post(
            @config.healthie_url,
            body: { query: query, variables: variables }.to_json,
            headers: headers
          )
          handle_response(response)
        end

        # Creates a new patient (client) in Healthie.
        #
        # @param input [Hash] patient data
        # @option input [String] :first_name Patient's first name (required)
        # @option input [String] :last_name Patient's last name (required)
        # @option input [String] :email Patient's email address (required)
        # @option input [String] :phone_number Patient's phone number
        # @option input [String] :dietitian_id Provider/dietitian ID (required)
        # @option input [String] :additional_record_identifier External ID
        # @option input [String] :user_group_id User group ID
        # @option input [Boolean] :skipped_email Whether to skip email
        # @option input [Boolean] :dont_send_welcome Skip welcome email
        # @return [Hash] response containing user data and any messages
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.create_patient({
        #     first_name: "John",
        #     last_name: "Doe",
        #     email: "john@example.com",
        #     dietitian_id: "123"
        #   })
        #   patient_id = response.dig("data", "createClient", "user", "id")
        def create_patient(input)
          query = <<~GRAPHQL
            mutation CreateClient($input: createClientInput!) {
              createClient(input: $input) {
                user {
                  id
                  first_name
                  last_name
                  email
                  skipped_email
                  phone_number
                  dietitian_id
                  user_group_id
                  additional_record_identifier
                }
                messages {
                  field
                  message
                }
              }
            }
          GRAPHQL

          execute_query(query, { input: input })
        end

        # Searches for patients by keyword.
        #
        # @param keywords [String] search keywords (name, email, etc.)
        # @return [Hash] response containing matching users array
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.search_patients("john")
        #   users = response.dig("data", "users")
        #   users.each { |u| puts u["name"] }
        def search_patients(keywords)
          query = <<~GRAPHQL
            query Users($keywords: String) {
              users(keywords: $keywords) {
                id
                name
                email
                first_name
                last_name
                phone_number
                dob
                gender
              }
            }
          GRAPHQL

          execute_query(query, { keywords: keywords })
        end

        # Retrieves a patient by ID with full details.
        #
        # @param patient_id [String] the Healthie patient/user ID
        # @return [Hash] response containing user data with location, providers, etc.
        # @raise [APIError] if the request fails or patient not found
        #
        # @example
        #   response = client.get_patient("123456")
        #   user = response.dig("data", "user")
        #   puts "#{user['name']} - #{user['email']}"
        def get_patient(patient_id)
          query = <<~GRAPHQL
            query getUser($id: ID) {
              user(id: $id) {
                id
                name
                dob
                first_name
                last_name
                timezone
                height
                weight
                next_appt_date
                location {
                  line1
                  line2
                  zip
                  state
                  city
                  country
                }
                age
                created_at
                updated_at
                email
                bmi_percentile
                providers {
                  id
                  name
                }
                phone_number
                gender
                dietitian_id
                policies {
                  id
                  insurance_plan {
                    name_and_id
                    payer_id
                    payer_name
                  }
                  insurance_plan_id
                }
              }
            }
          GRAPHQL

          execute_query(query, { id: patient_id })
        end

        # Updates an existing patient's information.
        #
        # @param input [Hash] patient update data
        # @option input [String] :id Patient ID (required)
        # @option input [String] :dob Date of birth (MM/DD/YYYY format)
        # @option input [String] :gender Patient's gender
        # @option input [String] :height Height in inches
        # @option input [String] :additional_record_identifier External ID
        # @option input [Hash] :location Address information
        # @return [Hash] response containing updated user data and messages
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.update_patient({
        #     id: "123456",
        #     dob: "01/15/1990",
        #     location: { city: "Austin", state: "TX", zip: "78701" }
        #   })
        def update_patient(input)
          query = <<~GRAPHQL
            mutation UpdateClient($input: updateClientInput!) {
              updateClient(input: $input) {
                user {
                  id
                  dob
                  gender
                  height
                  additional_record_identifier
                  location {
                    city
                    line1
                    line2
                    state
                    zip
                    country
                  }
                }
                messages {
                  field
                  message
                }
              }
            }
          GRAPHQL

          execute_query(query, { input: input })
        end

        # Uploads a document for a patient.
        #
        # @param input [Hash] document upload data
        # @option input [String] :file_string Base64-encoded file data with MIME type
        # @option input [String] :display_name Display name for the document
        # @option input [String] :rel_user_id Patient ID to associate document with
        # @return [Hash] response containing document ID and owner info
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.upload_document({
        #     file_string: "data:image/jpeg;base64,/9j/4AAQ...",
        #     display_name: "Lab Results 2024",
        #     rel_user_id: "123456"
        #   })
        def upload_document(input)
          query = <<~GRAPHQL
            mutation CreateDocument($input: createDocumentInput!) {
              createDocument(input: $input) {
                document {
                  id
                  owner {
                    id
                  }
                }
                currentUser {
                  id
                  email
                }
                messages {
                  field
                  message
                }
              }
            }
          GRAPHQL

          execute_query(query, { input: input })
        end

        # Creates a metric entry (e.g., weight) for a patient.
        #
        # @param input [Hash] metric entry data
        # @option input [String] :category Metric category (e.g., "Weight")
        # @option input [String] :type Entry type (e.g., "MetricEntry")
        # @option input [String] :metric_stat The metric value
        # @option input [String] :user_id Patient ID
        # @option input [String] :created_at Entry date (M/D/YYYY format)
        # @return [Hash] response containing entry ID and messages
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.create_metric_entry({
        #     category: "Weight",
        #     type: "MetricEntry",
        #     metric_stat: "180",
        #     user_id: "123456",
        #     created_at: "1/15/2024"
        #   })
        def create_metric_entry(input)
          query = <<~GRAPHQL
            mutation createEntry (
              $metric_stat: String,
              $category: String,
              $type: String,
              $user_id: String
              $created_at: String
            ) {
              createEntry (input:{
                category: $category,
                type: $type,
                metric_stat: $metric_stat,
                user_id: $user_id,
                created_at: $created_at,
              })
              {
                entry {
                  id
                  category
                  type
                }
                messages {
                  field
                  message
                }
              }
            }
          GRAPHQL

          execute_query(query, input)
        end

        # Creates an invoice/requested payment for a patient.
        #
        # @param input [Hash] invoice data
        # @option input [String] :recipient_id Patient ID (required)
        # @option input [String] :price Invoice amount (required)
        # @option input [String] :status Payment status (e.g., "Paid")
        # @option input [String] :services_provided Description of services
        # @option input [String] :offering_id Associated offering ID
        # @option input [String] :invoice_type Type of invoice
        # @option input [String] :notes Additional notes
        # @return [Hash] response containing payment ID and messages
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.create_invoice({
        #     recipient_id: "123456",
        #     price: "299",
        #     status: "Paid",
        #     services_provided: "TRT Monthly Subscription"
        #   })
        def create_invoice(input)
          query = <<~GRAPHQL
            mutation createRequestedPayment(
              $recipient_id: ID,
              $offering_id: ID,
              $price: String,
              $invoice_type: String,
              $status: String,
              $notes: String,
              $services_provided: String
            ) {
              createRequestedPayment(input: {
                recipient_id: $recipient_id,
                offering_id: $offering_id,
                price: $price,
                invoice_type: $invoice_type,
                status: $status,
                notes: $notes,
                services_provided: $services_provided
              })
              {
                requestedPayment {
                  id
                }
                messages {
                  field
                  message
                }
              }
            }
          GRAPHQL

          execute_query(query, input)
        end

        # Retrieves appointments for a patient.
        #
        # @param user_id [String] the patient/user ID
        # @param filter [String] appointment filter ("all", "upcoming", "past")
        # @return [Hash] response containing appointments array and count
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.get_patient_appointments("123456", "upcoming")
        #   appointments = response.dig("data", "appointments")
        #   appointments.each { |a| puts "#{a['date']} - #{a.dig('provider', 'full_name')}" }
        def get_patient_appointments(user_id, filter = "all")
          query = <<~GRAPHQL
            query appointments($user_id: ID, $filter: String) {
              appointmentsCount(user_id: $user_id, filter: $filter)
              appointments(user_id: $user_id, filter: $filter) {
                id
                date
                contact_type
                created_at
                length
                location
                provider {
                  full_name
                }
                appointment_type {
                  name
                  id
                }
                attendees {
                  full_name
                }
              }
            }
          GRAPHQL

          execute_query(query, { user_id: user_id, filter: filter })
        end

        # Retrieves detailed information for a specific appointment.
        #
        # @param appointment_id [String] the appointment ID
        # @return [Hash] response containing full appointment details
        # @raise [APIError] if the request fails or appointment not found
        #
        # @example
        #   response = client.get_appointment("2037619")
        #   appointment = response.dig("data", "appointment")
        #   puts "Date: #{appointment['date']}"
        #   puts "Provider: #{appointment.dig('provider', 'name')}"
        def get_appointment(appointment_id)
          query = <<~GRAPHQL
            query Appointment($id: ID!) {
              appointment(id: $id) {
                id
                length
                date
                pm_status
                user_id
                updated_at
                timezone_abbr
                external_videochat_url
                provider {
                  name
                  id
                  email
                  npi
                  organization {
                    name
                    id
                  }
                }
                appointment_type {
                  id
                }
                requested_payment {
                  id
                }
                user {
                  id
                  first_name
                  last_name
                  full_name
                  email
                }
              }
            }
          GRAPHQL

          execute_query(query, { id: appointment_id })
        end

        # Cancels an appointment by updating its status to "Cancelled".
        #
        # @param appointment_id [String] the appointment ID to cancel
        # @return [Hash] response containing updated appointment with pm_status
        # @raise [APIError] if the request fails
        #
        # @example
        #   response = client.cancel_appointment("2037619")
        #   status = response.dig("data", "updateAppointment", "appointment", "pm_status")
        #   puts "Status: #{status}"  # => "Cancelled"
        def cancel_appointment(appointment_id)
          mutation = <<~GRAPHQL
            mutation updateAppointment($input: updateAppointmentInput) {
              updateAppointment(input: $input) {
                appointment {
                  id
                  pm_status
                }
              }
            }
          GRAPHQL

          execute_query(mutation, { input: { id: appointment_id, pm_status: 'Cancelled' } })
        end

        private

        # @api private
        # Builds authentication headers based on configured credentials.
        # Uses Bearer token if openloop_api_key is set, otherwise Basic auth.
        def headers
          headers = {
            "Content-Type" => "application/json",
            "AuthorizationSource" => "API"
          }

          if @config.openloop_api_key
            headers["Authorization"] = "Bearer #{@config.openloop_api_key}"
            headers["AuthorizationShard"] = @config.healthie_authorization_shard if @config.healthie_authorization_shard
          else
            headers["Authorization"] = "Basic #{@config.healthie_api_key}"
          end

          headers
        end
      end
    end
  end
end
