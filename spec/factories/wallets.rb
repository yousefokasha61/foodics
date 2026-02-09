# frozen_string_literal: true

FactoryBot.define do
  factory :wallet do
    sequence(:name) { |n| "Wallet #{n}" }
    sequence(:account_number) { |n| "SA698000020460801621290#{n}" }
    balance_cents { 0 }
  end
end
