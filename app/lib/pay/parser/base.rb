# frozen_string_literal: true

module Pay
  module Parser
    class Base
      def parse(raw_payload)
        transactions = []
        errors = []

        raw_payload.each_line.with_index(1) do |line, line_number|
          line = line.strip
          next if line.empty?

          begin
            transactions << parse_line(line)
          rescue StandardError => e
            errors << { line: line_number, raw: line, error: e.message }
          end
        end

        Result.new(transactions: transactions, errors: errors)
      end

      private

      def parse_line(_line)
        raise NotImplementedError, "Subclasses must implement parse_line"
      end

      # Convert European format "156,50" to cents (15650)
      def parse_amount_to_cents(amount_str)
        (amount_str.gsub(",", ".").to_f * 100).to_i
      end

      # Parse date from YYYYMMDD format
      def parse_date(date_str)
        Date.strptime(date_str, "%Y%m%d")
      end
    end
  end
end
