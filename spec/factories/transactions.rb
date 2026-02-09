# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    wallet
    webhook
    bank { "FOODICS" }
    sequence(:reference) { |n| "REF#{n}" }
    amount_cents { 15650 }
    transaction_date { Date.new(2025, 6, 15) }
    metadata { {} }
  end
end
