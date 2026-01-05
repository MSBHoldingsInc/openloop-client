# frozen_string_literal: true

module OpenLoop
  module Client
    module GraphQL
      module Mutations
        class CreateInvoice < BaseMutation
          argument :recipient_id, ID, required: true
          argument :price, String, required: true
          argument :status, String, required: false
          argument :services_provided, String, required: false
          argument :offering_id, ID, required: false
          argument :invoice_type, String, required: false
          argument :notes, String, required: false

          field :success, Boolean, null: false
          field :invoice_id, ID, null: true
          field :errors, [String], null: true

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
