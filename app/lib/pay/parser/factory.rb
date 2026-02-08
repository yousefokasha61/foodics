# frozen_string_literal: true

module Pay
  module Parser
    class Factory
      PARSERS = {
        "foodics" => FoodicsBank,
        "acme" => AcmeBank
      }.freeze

      def self.for(bank)
        parser_class = PARSERS[bank.to_s.downcase]
        raise ArgumentError, "Unknown bank: #{bank}" unless parser_class

        parser_class.new
      end
    end
  end
end
