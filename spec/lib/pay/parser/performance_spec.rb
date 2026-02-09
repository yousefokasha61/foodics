# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Parser Performance", type: :performance do
  describe "parsing 1,000 transactions" do
    let(:transaction_count) { 1_000 }

    context "with Foodics Bank format" do
      let(:parser) { Pay::Parser::FoodicsBank.new }

      let(:payload) do
        (1..transaction_count).map do |i|
          date = (Date.new(2025, 1, 1) + i.days).strftime("%Y%m%d")
          amount = format("%d,%02d", i * 10, i % 100)
          reference = format("REF%09d", i)
          "#{date}#{amount}##{reference}#note/transaction #{i}"
        end.join("\n")
      end

      it "parses all 1,000 transactions successfully" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(transaction_count)
        expect(result.errors).to be_empty
      end

      it "completes within acceptable time (< 1 second)" do
        start_time = Time.current
        parser.parse(payload)
        elapsed = Time.current - start_time

        expect(elapsed).to be < 1.0
        puts "Foodics Bank: Parsed #{transaction_count} transactions in #{(elapsed * 1000).round(2)}ms"
      end

      it "maintains data integrity for all transactions" do
        result = parser.parse(payload)

        # Check first transaction
        first_tx = result.transactions.first
        expect(first_tx.reference).to eq("REF000000001")
        expect(first_tx.transaction_date).to eq(Date.new(2025, 1, 2))

        # Check last transaction
        last_tx = result.transactions.last
        expect(last_tx.reference).to eq("REF000001000")
        expect(last_tx.transaction_date).to eq(Date.new(2027, 9, 28))

        # Verify all references are unique
        references = result.transactions.map(&:reference)
        expect(references.uniq.size).to eq(transaction_count)
      end
    end

    context "with Acme Bank format" do
      let(:parser) { Pay::Parser::AcmeBank.new }

      let(:payload) do
        (1..transaction_count).map do |i|
          date = (Date.new(2025, 1, 1) + i.days).strftime("%Y%m%d")
          amount = format("%d,%02d", i * 10, i % 100)
          reference = format("REF%09d", i)
          "#{amount}//#{reference}//#{date}"
        end.join("\n")
      end

      it "parses all 1,000 transactions successfully" do
        result = parser.parse(payload)

        expect(result.transactions.size).to eq(transaction_count)
        expect(result.errors).to be_empty
      end

      it "completes within acceptable time (< 1 second)" do
        start_time = Time.current
        parser.parse(payload)
        elapsed = Time.current - start_time

        expect(elapsed).to be < 1.0
        puts "Acme Bank: Parsed #{transaction_count} transactions in #{(elapsed * 1000).round(2)}ms"
      end
    end
  end

  describe "processing 1,000 transactions via webhook service" do
    include_context "with redis"

    let(:wallet) { create(:wallet, balance_cents: 0) }
    let(:service) { Pay::Webhook::Service.new(wallet_id: wallet.id) }
    let(:transaction_count) { 1_000 }

    # Use consistent amounts for easier calculation
    let(:payload) do
      (1..transaction_count).map do |i|
        date = (Date.new(2025, 1, 1) + i.days).strftime("%Y%m%d")
        reference = format("PERF%09d", i)
        "#{date}100,00##{reference}#" # Each transaction is exactly 100.00 (10000 cents)
      end.join("\n")
    end

    let!(:webhook) do
      create(:webhook,
             wallet: wallet,
             bank: "FOODICS",
             raw_payload: payload)
    end

    it "processes all 1,000 transactions" do
      expect {
        service.process(webhook_id: webhook.id)
      }.to change(Transaction, :count).by(transaction_count)
    end

    it "completes within acceptable time (< 5 seconds)" do
      start_time = Time.current
      service.process(webhook_id: webhook.id)
      elapsed = Time.current - start_time

      expect(elapsed).to be < 5.0
      puts "Full processing: #{transaction_count} transactions in #{(elapsed * 1000).round(2)}ms"
    end

    it "correctly updates wallet balance" do
      service.process(webhook_id: webhook.id)

      # Each transaction is 100.00 = 10000 cents
      # 1000 transactions * 10000 cents = 10,000,000 cents
      expected_balance = transaction_count * 10_000

      wallet.reload
      expect(wallet.balance_cents).to eq(expected_balance)
    end
  end
end
