# frozen_string_literal: true

module Pay
  module Parser
    # Parses Foodics Bank webhook format:
    # 20250615156,50#202506159000001#note/debt payment march/internal_reference/A462JE81
    #
    # Format: Date(8) + Amount#Reference#key/value pairs
    class FoodicsBank < Base
      DATE_LENGTH = 8

      private

      def parse_line(line)
        parts = line.split("#")
        raise "Invalid format: expected at least 2 parts separated by #" if parts.length < 2

        date_and_amount = parts[0]
        reference = parts[1]
        metadata_part = parts[2]

        date_str = date_and_amount[0, DATE_LENGTH]
        amount_str = date_and_amount[DATE_LENGTH..]

        raise "Invalid date format" if date_str.nil? || date_str.length != DATE_LENGTH
        raise "Invalid amount" if amount_str.nil? || amount_str.empty?

        ParsedTransaction.new(
          reference: reference,
          amount_cents: parse_amount_to_cents(amount_str),
          transaction_date: parse_date(date_str),
          metadata: parse_metadata(metadata_part)
        )
      end

      def parse_metadata(metadata_str)
        return {} if metadata_str.nil? || metadata_str.empty?

        metadata_str.split("/").each_slice(2).to_h do |key, value|
          [ key.to_s, value.to_s ]
        end
      end

      def parse_amount_to_cents(amount_str)
        (amount_str.gsub(",", ".").to_f * 100).to_i
      end
    end
  end
end
