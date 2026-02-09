# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Payments", type: :request do
  let!(:wallet) { create(:wallet) }

  describe "POST /api/v1/wallets/:wallet_id/payments" do
    let(:valid_params) do
      {
        receiver: {
          bank_code: "FDCSSARI",
          account_number: "SA6980000204608016211111",
          beneficiary_name: "Jane Doe"
        },
        amount: 177.39,
        currency: "SAR",
        notes: ["Lorem Epsum", "Dolor Sit Amet"],
        payment_type: 421,
        charge_details: "RB"
      }
    end

    context "with valid params including all optional fields" do
      it "returns XML response" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/xml")
      end

      it "generates valid XML structure" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: valid_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("paymentrequestmessage")).to be_present
        expect(doc.at("transferinfo")).to be_present
        expect(doc.at("senderinfo")).to be_present
        expect(doc.at("receiverinfo")).to be_present
      end

      it "includes sender account from wallet" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: valid_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("senderinfo accountnumber").text).to eq(wallet.account_number)
      end

      it "includes receiver info from params" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: valid_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("receiverinfo bankcode").text).to eq("FDCSSARI")
        expect(doc.at("receiverinfo accountnumber").text).to eq("SA6980000204608016211111")
        expect(doc.at("receiverinfo beneficiaryname").text).to eq("Jane Doe")
      end

      it "includes notes when provided" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: valid_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.css("notes note").map(&:text)).to eq(["Lorem Epsum", "Dolor Sit Amet"])
      end

      it "includes payment type when not default" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: valid_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("paymenttype").text).to eq("421")
      end

      it "includes charge details when not default" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: valid_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("chargedetails").text).to eq("RB")
      end
    end

    context "with minimal params (only required fields)" do
      let(:minimal_params) do
        {
          receiver: {
            bank_code: "FDCSSARI",
            account_number: "SA6980000204608016211111",
            beneficiary_name: "Jane Doe"
          },
          amount: 100.0
        }
      end

      it "returns XML response" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: minimal_params,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it "omits notes tag" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: minimal_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("notes")).to be_nil
      end

      it "omits paymenttype tag (default 99)" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: minimal_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("paymenttype")).to be_nil
      end

      it "omits chargedetails tag (default SHA)" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: minimal_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("chargedetails")).to be_nil
      end

      it "uses SAR as default currency" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: minimal_params,
             as: :json

        doc = Nokogiri::XML(response.body)

        expect(doc.at("transferinfo currency").text).to eq("SAR")
      end
    end

    context "with invalid params" do
      it "returns error when receiver is missing" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: { amount: 100.0 },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error when amount is missing" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: {
               receiver: {
                 bank_code: "FDCSSARI",
                 account_number: "SA123",
                 beneficiary_name: "Jane"
               }
             },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error when amount is zero" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: {
               receiver: {
                 bank_code: "FDCSSARI",
                 account_number: "SA123",
                 beneficiary_name: "Jane"
               },
               amount: 0
             },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error when amount is negative" do
        post "/api/v1/wallets/#{wallet.id}/payments",
             params: {
               receiver: {
                 bank_code: "FDCSSARI",
                 account_number: "SA123",
                 beneficiary_name: "Jane"
               },
               amount: -100
             },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with non-existent wallet" do
      it "returns not found error" do
        post "/api/v1/wallets/999999/payments",
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
