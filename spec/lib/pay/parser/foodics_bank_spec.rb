# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pay::Parser::FoodicsBank do
  subject(:parser) { described_class.new }

  describe "#parse" do
    context "with valid single transaction" do
      let(:payload) { "20250615156,50#202506159000001#note/debt payment" }

      it "parses the transaction correctly" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(1)
        expect(result.errors).to be_empty

        tx = result.transactions.first
        expect(tx.reference).to eq("202506159000001")
        expect(tx.amount_cents).to eq(15650)
        expect(tx.transaction_date).to eq(Date.new(2025, 6, 15))
        expect(tx.metadata).to eq({ "note" => "debt payment" })
      end
    end

    context "with multiple key-value pairs in metadata" do
      let(:payload) { "20250615156,50#202506159000001#note/debt payment/internal_reference/A462JE81" }

      it "parses all metadata key-value pairs" do
        result = parser.parse(payload)

        tx = result.transactions.first
        expect(tx.metadata).to eq({
          "note" => "debt payment",
          "internal_reference" => "A462JE81"
        })
      end
    end

    context "with no metadata" do
      let(:payload) { "20250615156,50#202506159000001" }

      it "parses with empty metadata" do
        result = parser.parse(payload)

        tx = result.transactions.first
        expect(tx.reference).to eq("202506159000001")
        expect(tx.metadata).to eq({})
      end
    end

    context "with multiple transactions" do
      let(:payload) do
        <<~PAYLOAD
          20250615156,50#202506159000001#note/first
          20250616200,00#202506159000002#note/second
          20250617350,25#202506159000003#note/third
        PAYLOAD
      end

      it "parses all transactions" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(3)
        expect(result.errors).to be_empty

        expect(result.transactions[0].amount_cents).to eq(15650)
        expect(result.transactions[1].amount_cents).to eq(20000)
        expect(result.transactions[2].amount_cents).to eq(35025)
      end
    end

    context "with invalid line mixed with valid" do
      let(:payload) do
        <<~PAYLOAD
          20250615156,50#202506159000001#note/valid
          invalid line here
          20250616200,00#202506159000002#note/also valid
        PAYLOAD
      end

      it "parses valid lines and captures errors for invalid ones" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(2)
        expect(result.errors.size).to eq(1)
        expect(result.errors.first[:line]).to eq(2)
        expect(result.errors.first[:raw]).to eq("invalid line here")
      end
    end

    context "with empty payload" do
      let(:payload) { "" }

      it "returns empty transactions" do
        result = parser.parse(payload)

        expect(result.transactions).to be_empty
        expect(result.errors).to be_empty
      end
    end

    context "with blank lines" do
      let(:payload) do
        <<~PAYLOAD
          20250615156,50#202506159000001#note/first

          20250616200,00#202506159000002#note/second

        PAYLOAD
      end

      it "skips blank lines" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(2)
        expect(result.errors).to be_empty
      end
    end

    context "with decimal amounts" do
      let(:payload) { "202506151234,56#REF001#" }

      it "converts European format to cents correctly" do
        result = parser.parse(payload)

        tx = result.transactions.first
        expect(tx.amount_cents).to eq(123456)
      end
    end
  end
end
