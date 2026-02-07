class Webhook < ApplicationRecord
  belongs_to :wallet
  has_many :transactions, dependent: :destroy

  scope :pending, -> { where(status: "PENDING") }
  scope :processing, -> { where(status: "PROCESSING") }
  scope :processed, -> { where(status: "PROCESSED") }
  scope :failed, -> { where(status: "FAILED") }

  def pending?
    status == "PENDING"
  end

  def processed?
    status == "PROCESSED"
  end

  def mark_as_processing!
    update!(status: "PROCESSING")
  end

  def mark_as_processed!
    update!(status: "PROCESSED")
  end

  def mark_as_failed!
    update!(status: "FAILED")
  end
end
