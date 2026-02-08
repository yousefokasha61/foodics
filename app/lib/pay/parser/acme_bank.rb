# frozen_string_literal: true

module Pay
  module Parser
    # Parses Acme Bank webhook format:
    # 156,50//202506159000001//20250615
    #
    # Format: Amount//Reference//Date
    class AcmeBank < Base
      SEPARATOR = "//"

      private

      def parse_line(line)
        parts = line.split(SEPARATOR)
        raise "Invalid format: expected 3 parts separated by //" if parts.length != 3

        amount_str = parts[0]
        reference = parts[1]
        date_str = parts[2]

        raise "Invalid amount" if amount_str.nil? || amount_str.empty?
        raise "Invalid reference" if reference.nil? || reference.empty?
        raise "Invalid date" if date_str.nil? || date_str.length != 8

        ParsedTransaction.new(
          reference: reference,
          amount_cents: parse_amount_to_cents(amount_str),
          transaction_date: parse_date(date_str),
          metadata: {}
        )
      end

      def parse_amount_to_cents(amount_str)
        (amount_str.gsub(",", ".").to_f * 100).to_i
      end
    end
  end
end
