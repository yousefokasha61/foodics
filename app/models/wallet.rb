class Wallet < ApplicationRecord
  has_many :webhooks, dependent: :destroy
  has_many :transactions, dependent: :destroy

  def balance
    balance_cents / 100.0
  end
end
