class Webhook < ApplicationRecord
  belongs_to :wallet
  has_many :transactions, dependent: :destroy

  scope :pending, -> { where(status: "PENDING") }
  scope :processing, -> { where(status: "PROCESSING") }
  scope :processed, -> { where(status: "PROCESSED") }
  scope :partially_processed, -> { where(status: "PARTIALLY_PROCESSED") }
  scope :failed, -> { where(status: "FAILED") }

  def pending?
    status == "PENDING"
  end

  def processed?
    status == "PROCESSED"
  end

  def partially_processed?
    status == "PARTIALLY_PROCESSED"
  end

  def mark_as_processing!
    update!(status: "PROCESSING")
  end

  def mark_as_processed!(processing_errors: [])
    if processing_errors.any?
      update!(status: "PARTIALLY_PROCESSED", processing_errors: processing_errors)
    else
      update!(status: "PROCESSED")
    end
  end

  def mark_as_failed!(processing_errors: [])
    update!(status: "FAILED", processing_errors: processing_errors)
  end
end
