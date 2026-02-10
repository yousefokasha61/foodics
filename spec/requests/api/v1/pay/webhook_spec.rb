# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Pay::Webhook", type: :request do
  include_context "with redis"

  let!(:wallet) { create(:wallet) }

  describe "POST /api/v1/pay/webhook" do
    let(:headers) do
      {
        "X-Wallet-ID" => wallet.id.to_s,
        "X-Bank" => "FOODICS",
        "CONTENT_TYPE" => "text/plain"
      }
    end

    context "with valid Foodics Bank payload" do
      let(:payload) { "20250615156,50#202506159000001#note/debt payment" }

      it "creates a webhook record" do
        expect {
          post "/api/v1/pay/webhook",
               params: payload,
               headers: headers.merge("RAW_POST_DATA" => payload)
        }.to change(Webhook, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "stores the raw payload" do
        post "/api/v1/pay/webhook",
             params: payload,
             headers: headers.merge("RAW_POST_DATA" => payload)

        webhook = Webhook.last
        expect(webhook.raw_payload).to eq(payload)
        expect(webhook.bank).to eq("FOODICS")
      end

      it "enqueues a processing job" do
        expect {
          post "/api/v1/pay/webhook",
               params: payload,
               headers: headers.merge("RAW_POST_DATA" => payload)
        }.to have_enqueued_job(ProcessWebhookJob)
      end
    end

    context "with valid Acme Bank payload" do
      let(:payload) { "156,50//202506159000001//20250615" }
      let(:acme_headers) { headers.merge("X-Bank" => "ACME") }

      it "creates a webhook with acme bank" do
        post "/api/v1/pay/webhook",
             params: payload,
             headers: acme_headers.merge("RAW_POST_DATA" => payload)

        expect(response).to have_http_status(:created)

        webhook = Webhook.last
        expect(webhook.bank).to eq("ACME")
      end
    end

    context "when ingestion is disabled" do
      before do
        Pay::Webhook::Ingestion::Cache.new.disable!
      end

      it "still creates the webhook" do
        payload = "20250615156,50#REF001#"

        expect {
          post "/api/v1/pay/webhook",
               params: payload,
               headers: headers.merge("RAW_POST_DATA" => payload)
        }.to change(Webhook, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "does not enqueue a processing job" do
        payload = "20250615156,50#REF001#"

        expect {
          post "/api/v1/pay/webhook",
               params: payload,
               headers: headers.merge("RAW_POST_DATA" => payload)
        }.not_to have_enqueued_job(ProcessWebhookJob)
      end

      it "keeps webhook in PENDING status" do
        payload = "20250615156,50#REF001#"

        post "/api/v1/pay/webhook",
             params: payload,
             headers: headers.merge("RAW_POST_DATA" => payload)

        expect(Webhook.last.status).to eq("PENDING")
      end
    end

    context "with non-existent wallet" do
      it "returns not found error" do
        payload = "20250615156,50#REF001#"

        post "/api/v1/pay/webhook",
             params: payload,
             headers: headers.merge("X-Wallet-ID" => "999999", "RAW_POST_DATA" => payload)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with missing X-Wallet-ID header" do
      it "returns bad request error" do
        payload = "20250615156,50#REF001#"

        post "/api/v1/pay/webhook",
             params: payload,
             headers: { "X-Bank" => "FOODICS", "CONTENT_TYPE" => "text/plain", "RAW_POST_DATA" => payload }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with invalid bank" do
      it "returns bad request error" do
        payload = "20250615156,50#REF001#"

        post "/api/v1/pay/webhook",
             params: payload,
             headers: headers.merge("X-Bank" => "INVALID", "RAW_POST_DATA" => payload)

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
