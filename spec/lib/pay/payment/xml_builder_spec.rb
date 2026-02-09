# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pay::Payment::XmlBuilder do
  subject(:builder) { described_class.new(payment_request) }

  let(:base_attributes) do
    {
      reference: "e0f4763d-28ea-42d4-ac1c-c4013c242105",
      date: "2025-02-25 06:33:00+0300",
      amount: 177.39,
      currency: "SAR",
      sender_account_number: "SA6980000204608016212908",
      receiver_bank_code: "FDCSSARI",
      receiver_account_number: "SA6980000204608016211111",
      beneficiary_name: "Jane Doe"
    }
  end

  describe "#build" do
    context "with all optional fields provided" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(
          **base_attributes,
          notes: ["Lorem Epsum", "Dolor Sit Amet"],
          payment_type: 421,
          charge_details: "RB"
        )
      end

      it "generates complete XML with all tags" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        # Transfer info
        expect(doc.at("transferinfo reference").text).to eq("e0f4763d-28ea-42d4-ac1c-c4013c242105")
        expect(doc.at("transferinfo date").text).to eq("2025-02-25 06:33:00+0300")
        expect(doc.at("transferinfo amount").text).to eq("177.39")
        expect(doc.at("transferinfo currency").text).to eq("SAR")

        # Sender info
        expect(doc.at("senderinfo accountnumber").text).to eq("SA6980000204608016212908")

        # Receiver info
        expect(doc.at("receiverinfo bankcode").text).to eq("FDCSSARI")
        expect(doc.at("receiverinfo accountnumber").text).to eq("SA6980000204608016211111")
        expect(doc.at("receiverinfo beneficiaryname").text).to eq("Jane Doe")

        # Optional fields present
        expect(doc.css("notes note").map(&:text)).to eq(["Lorem Epsum", "Dolor Sit Amet"])
        expect(doc.at("paymenttype").text).to eq("421")
        expect(doc.at("chargedetails").text).to eq("RB")
      end

      it "includes XML declaration with utf-8 encoding" do
        xml = builder.build
        expect(xml).to include('<?xml version="1.0" encoding="utf-8"?>')
      end
    end

    context "with default values (no optional fields)" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes)
      end

      it "omits notes tag when notes array is empty" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("notes")).to be_nil
      end

      it "omits paymenttype tag when value is 99 (default)" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("paymenttype")).to be_nil
      end

      it "omits chargedetails tag when value is SHA (default)" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("chargedetails")).to be_nil
      end
    end

    context "with payment_type = 99 explicitly" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes, payment_type: 99)
      end

      it "omits paymenttype tag" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("paymenttype")).to be_nil
      end
    end

    context "with charge_details = SHA explicitly" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes, charge_details: "SHA")
      end

      it "omits chargedetails tag" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("chargedetails")).to be_nil
      end
    end

    context "with single note" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes, notes: ["Single note"])
      end

      it "includes notes tag with one note" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.css("notes note").size).to eq(1)
        expect(doc.at("notes note").text).to eq("Single note")
      end
    end

    context "with payment_type != 99" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes, payment_type: 100)
      end

      it "includes paymenttype tag" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("paymenttype").text).to eq("100")
      end
    end

    context "with charge_details != SHA" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes, charge_details: "OUR")
      end

      it "includes chargedetails tag" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("chargedetails").text).to eq("OUR")
      end
    end

    context "with amount formatting" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes, amount: 100.5)
      end

      it "formats amount with two decimal places" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("transferinfo amount").text).to eq("100.50")
      end
    end

    context "with whole number amount" do
      let(:payment_request) do
        Pay::Payment::PaymentRequest.new(**base_attributes, amount: 100.0)
      end

      it "formats amount with two decimal places" do
        xml = builder.build
        doc = Nokogiri::XML(xml)

        expect(doc.at("transferinfo amount").text).to eq("100.00")
      end
    end
  end
end
