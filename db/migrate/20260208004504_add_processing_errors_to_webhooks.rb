class AddProcessingErrorsToWebhooks < ActiveRecord::Migration[8.0]
  def change
    add_column :webhooks, :processing_errors, :jsonb, null: false, default: []
  end
end
