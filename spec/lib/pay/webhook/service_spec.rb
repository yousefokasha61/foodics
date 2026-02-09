# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pay::Webhook::Service do
  include_context "with redis"

  let(:wallet) { create(:wallet, balance_cents: 0) }
  let(:service) { described_class.new(wallet_id: wallet.id) }

  describe "#process" do
    context "with valid Foodics Bank webhook" do
      let!(:webhook) do
        create(:webhook,
               wallet: wallet,
               bank: "FOODICS",
               raw_payload: "20250615156,50#REF001#note/test")
      end

      it "creates transactions from the webhook" do
        expect {
          service.process(webhook_id: webhook.id)
        }.to change(Transaction, :count).by(1)
      end

      it "updates wallet balance" do
        service.process(webhook_id: webhook.id)

        wallet.reload
        expect(wallet.balance_cents).to eq(15650)
      end

      it "marks webhook as processed" do
        service.process(webhook_id: webhook.id)

        webhook.reload
        expect(webhook.status).to eq("PROCESSED")
      end

      it "returns Success with the webhook" do
        result = service.process(webhook_id: webhook.id)

        expect(result).to be_success
        expect(result.value!).to eq(webhook.reload)
      end
    end

    context "with multiple transactions" do
      let(:payload) do
        <<~PAYLOAD
          20250615100,00#MULTI_REF001#
          20250615200,00#MULTI_REF002#
          20250615300,00#MULTI_REF003#
        PAYLOAD
      end

      let!(:webhook) do
        create(:webhook,
               wallet: wallet,
               bank: "FOODICS",
               raw_payload: payload)
      end

      it "creates all transactions" do
        expect {
          service.process(webhook_id: webhook.id)
        }.to change(Transaction, :count).by(3)
      end

      it "updates wallet balance with sum of all transactions" do
        service.process(webhook_id: webhook.id)

        wallet.reload
        expect(wallet.balance_cents).to eq(60000) # 100 + 200 + 300
      end
    end

    context "with duplicate transactions (idempotency)" do
      let!(:webhook) do
        create(:webhook,
               wallet: wallet,
               bank: "FOODICS",
               raw_payload: "20250615100,00#EXISTING_REF001#")
      end

      let!(:existing_transaction) do
        create(:transaction,
               wallet: wallet,
               webhook: webhook,
               bank: "FOODICS",
               reference: "EXISTING_REF001",
               amount_cents: 10000)
      end

      let!(:duplicate_webhook) do
        create(:webhook,
               wallet: wallet,
               bank: "FOODICS",
               raw_payload: "20250615100,00#EXISTING_REF001#")
      end

      it "does not create duplicate transaction" do
        expect {
          service.process(webhook_id: duplicate_webhook.id)
        }.not_to change(Transaction, :count)
      end

      it "does not update wallet balance for duplicates" do
        original_balance = wallet.balance_cents

        service.process(webhook_id: duplicate_webhook.id)

        wallet.reload
        expect(wallet.balance_cents).to eq(original_balance)
      end
    end

    context "when webhook is already being processed" do
      let!(:webhook) do
        create(:webhook, :processing, wallet: wallet)
      end

      it "returns already_processing" do
        result = service.process(webhook_id: webhook.id)

        expect(result).to be_success
        expect(result.value!).to eq(:already_processing)
      end
    end

    context "with parsing errors" do
      let!(:webhook) do
        create(:webhook,
               wallet: wallet,
               bank: "FOODICS",
               raw_payload: "20250615100,00#PARTIAL_REF001#\ninvalid line\n20250615200,00#PARTIAL_REF002#")
      end

      it "marks webhook as partially processed" do
        service.process(webhook_id: webhook.id)

        webhook.reload
        expect(webhook.status).to eq("PARTIALLY_PROCESSED")
        expect(webhook.processing_errors).not_to be_empty
      end

      it "still processes valid transactions" do
        expect {
          service.process(webhook_id: webhook.id)
        }.to change(Transaction, :count).by(2)
      end
    end

    context "with all invalid lines" do
      let!(:webhook) do
        create(:webhook,
               wallet: wallet,
               bank: "FOODICS",
               raw_payload: "invalid line 1\ninvalid line 2")
      end

      it "marks webhook as failed" do
        service.process(webhook_id: webhook.id)

        webhook.reload
        expect(webhook.status).to eq("FAILED")
      end
    end
  end

  describe "#enqueue_pending_webhooks" do
    let!(:pending_webhooks) do
      3.times.map do |i|
        create(:webhook, wallet: wallet, status: "PENDING", raw_payload: "20250615100,00#PENDING_REF#{i}#")
      end
    end

    let!(:processed_webhook) do
      create(:webhook, :processed, wallet: wallet)
    end

    it "enqueues only pending webhooks" do
      expect {
        service.enqueue_pending_webhooks
      }.to have_enqueued_job(ProcessWebhookJob).exactly(3).times
    end

    it "returns count of enqueued webhooks" do
      result = service.enqueue_pending_webhooks

      expect(result).to be_success
      expect(result.value!).to eq(3)
    end
  end
end
