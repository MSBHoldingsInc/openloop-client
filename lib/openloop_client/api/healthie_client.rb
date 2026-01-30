# frozen_string_literal: true

require 'uri'

module OpenLoop
  module Client
    module API
      class HealthieClient < BaseClient
        def initialize
          @config = OpenLoop::Client.configuration
        end

        def execute_query(query, variables = {})
          response = self.class.post(
            @config.healthie_url,
            body: { query: query, variables: variables }.to_json,
            headers: headers
          )
          handle_response(response)
        end

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

        def get_patient_appointments(user_id, filter = "all")
          query = <<~GRAPHQL
            query appointments($user_id: ID, $filter: String) {
              appointmentsCount(user_id: $user_id, filter: $filter)
              appointments(user_id: $user_id, filter: $filter) {
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

          execute_query(query, { user_id: user_id, filter: filter })
        end

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

          response = execute_query(query, { id: appointment_id })
          transform_appointment_response(response)
        end

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

        def get_form_answer_group(id)
          query = <<~GRAPHQL
            query FormAnswerGroup($id: ID!) {
              formAnswerGroup(id: $id) {
                id
                user_id
                finished
                record_created_at
                updated_at
                metadata
                custom_module_form {
                  id
                }
                form_answers {
                  label
                  answer
                }
                locked_at
                locked_by {
                  full_name
                  profession
                }
                appointment {
                  id
                  provider_name
                }
                user {
                  id
                  email
                }
                current_summary {
                  id
                  summary
                }
                individual_client_notes {
                  id
                  content
                }
              }
            }
          GRAPHQL

          execute_query(query, { id: id })
        end

        private

        def transform_appointment_response(response)
          appointment = response.dig("data", "appointment")
          return response unless appointment

          external_videochat_url = appointment["external_videochat_url"]
          user = appointment["user"]

          if external_videochat_url && user && user["full_name"] && user["id"]
            encoded_username = URI.encode_www_form_component(user['full_name'])
            appointment["appointment_url"] = "#{external_videochat_url}?username=#{encoded_username}&autocheckin=false&pid=#{user['id']}"
          end

          response
        end

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
