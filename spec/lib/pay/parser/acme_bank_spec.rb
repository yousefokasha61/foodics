# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pay::Parser::AcmeBank do
  subject(:parser) { described_class.new }

  describe "#parse" do
    context "with valid single transaction" do
      let(:payload) { "156,50//202506159000001//20250615" }

      it "parses the transaction correctly" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(1)
        expect(result.errors).to be_empty

        tx = result.transactions.first
        expect(tx.reference).to eq("202506159000001")
        expect(tx.amount_cents).to eq(15650)
        expect(tx.transaction_date).to eq(Date.new(2025, 6, 15))
        expect(tx.metadata).to eq({})
      end
    end

    context "with multiple transactions" do
      let(:payload) do
        <<~PAYLOAD
          156,50//REF001//20250615
          200,00//REF002//20250616
          350,25//REF003//20250617
        PAYLOAD
      end

      it "parses all transactions" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(3)
        expect(result.errors).to be_empty

        expect(result.transactions[0].reference).to eq("REF001")
        expect(result.transactions[1].reference).to eq("REF002")
        expect(result.transactions[2].reference).to eq("REF003")
      end
    end

    context "with invalid format" do
      let(:payload) { "156,50/REF001/20250615" } # Single slash instead of double

      it "captures the error" do
        result = parser.parse(payload)

        expect(result.transactions).to be_empty
        expect(result.errors.size).to eq(1)
        expect(result.errors.first[:error]).to include("expected 3 parts")
      end
    end

    context "with invalid date format" do
      let(:payload) { "156,50//REF001//2025061" } # Date too short

      it "captures the error" do
        result = parser.parse(payload)

        expect(result.transactions).to be_empty
        expect(result.errors.size).to eq(1)
        expect(result.errors.first[:error]).to include("Invalid date")
      end
    end

    context "with mixed valid and invalid lines" do
      let(:payload) do
        <<~PAYLOAD
          156,50//REF001//20250615
          bad line
          200,00//REF002//20250616
        PAYLOAD
      end

      it "parses valid lines and captures errors" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(2)
        expect(result.errors.size).to eq(1)
        expect(result.errors.first[:line]).to eq(2)
      end
    end

    context "with empty amount" do
      let(:payload) { "//REF001//20250615" }

      it "captures the error" do
        result = parser.parse(payload)

        expect(result.transactions).to be_empty
        expect(result.errors.first[:error]).to include("Invalid amount")
      end
    end

    context "with large amounts" do
      let(:payload) { "999999,99//REF001//20250615" }

      it "handles large amounts correctly" do
        result = parser.parse(payload)

        tx = result.transactions.first
        expect(tx.amount_cents).to eq(99999999)
      end
    end
  end
end
