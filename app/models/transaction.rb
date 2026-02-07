class Transaction < ApplicationRecord
  belongs_to :wallet
  belongs_to :webhook

  def amount
    amount_cents / 100.0
  end
end
