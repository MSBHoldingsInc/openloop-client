# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        # Mutation for creating an invoice/requested payment for a patient.
        #
        # @example GraphQL mutation
        #   mutation {
        #     createInvoice(
        #       recipientId: "123456"
        #       price: "299"
        #       status: "Paid"
        #       servicesProvided: "TRT Monthly Subscription"
        #     ) {
        #       success
        #       invoiceId
        #       errors
        #     }
        #   }
        class CreateInvoice < BaseMutation
          # @!method recipient_id
          #   @return [ID] Patient ID to bill (required)
          argument :recipient_id, ID, required: true

          # @!method price
          #   @return [String] Invoice amount (required)
          argument :price, String, required: true

          # @!method status
          #   @return [String] Payment status (e.g., "Paid", "Unpaid")
          argument :status, String, required: false

          # @!method services_provided
          #   @return [String] Description of services
          argument :services_provided, String, required: false

          # @!method offering_id
          #   @return [ID] Associated offering ID
          argument :offering_id, ID, required: false

          # @!method invoice_type
          #   @return [String] Type of invoice
          argument :invoice_type, String, required: false

          # @!method notes
          #   @return [String] Additional notes
          argument :notes, String, required: false

          # @return [Boolean] Whether the invoice was created successfully
          field :success, Boolean, null: false

          # @return [ID, nil] ID of the created invoice
          field :invoice_id, ID, null: true

          # @return [Array<String>] Error messages if any
          field :errors, [String], null: true

          # Resolves the mutation by creating an invoice via Healthie API.
          #
          # @param args [Hash] mutation arguments
          # @return [Hash] hash with :success, :invoice_id, and :errors keys
          def resolve(**args)
            response = healthie_client.create_invoice(args)
            payment_data = response.dig("data", "createRequestedPayment", "requestedPayment")
            messages = response.dig("data", "createRequestedPayment", "messages")

            if payment_data
              { success: true, invoice_id: payment_data["id"], errors: [] }
            else
              { success: false, invoice_id: nil, errors: messages&.map { |m| "#{m['field']}: #{m['message']}" } || [] }
            end
          rescue API::BaseClient::APIError => e
            { success: false, invoice_id: nil, errors: [e.message] }
          end
        end
      end
    end
  end
end
