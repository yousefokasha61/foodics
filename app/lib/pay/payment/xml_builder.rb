# frozen_string_literal: true

module Pay
  module Payment
    class XmlBuilder
      def initialize(payment_request)
        @payment_request = payment_request
      end

      def build
        builder = Nokogiri::XML::Builder.new(encoding: "utf-8") do |xml|
          xml.paymentrequestmessage do
            build_transfer_info(xml)
            build_sender_info(xml)
            build_receiver_info(xml)
            build_notes(xml) if payment_request.notes?
            build_payment_type(xml) if payment_request.payment_type?
            build_charge_details(xml) if payment_request.charge_details?
          end
        end

        builder.to_xml
      end

      private

      attr_reader :payment_request

      def build_transfer_info(xml)
        xml.transferinfo do
          xml.reference payment_request.reference
          xml.date payment_request.date
          xml.amount format_amount(payment_request.amount)
          xml.currency payment_request.currency
        end
      end

      def build_sender_info(xml)
        xml.senderinfo do
          xml.accountnumber payment_request.sender_account_number
        end
      end

      def build_receiver_info(xml)
        xml.receiverinfo do
          xml.bankcode payment_request.receiver_bank_code
          xml.accountnumber payment_request.receiver_account_number
          xml.beneficiaryname payment_request.beneficiary_name
        end
      end

      def build_notes(xml)
        xml.notes do
          payment_request.notes.each do |note|
            xml.note note
          end
        end
      end

      def build_payment_type(xml)
        xml.paymenttype payment_request.payment_type
      end

      def build_charge_details(xml)
        xml.chargedetails payment_request.charge_details
      end

      def format_amount(amount)
        format("%.2f", amount)
      end
    end
  end
end
