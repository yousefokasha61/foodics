# frozen_string_literal: true

FactoryBot.define do
  factory :webhook do
    wallet
    bank { "FOODICS" }
    raw_payload { "20250615156,50#202506159000001#note/debt payment" }
    status { "PENDING" }

    trait :acme do
      bank { "ACME" }
      raw_payload { "156,50//202506159000001//20250615" }
    end

    trait :processing do
      status { "PROCESSING" }
    end

    trait :processed do
      status { "PROCESSED" }
    end

    trait :failed do
      status { "FAILED" }
    end
  end
end
