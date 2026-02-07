class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks do |t|
      t.references :wallet, null: false, foreign_key: true
      t.string :bank, null: false
      t.text :raw_payload, null: false
      t.string :status, null: false, default: "PENDING"

      t.timestamps
    end

    add_index :webhooks, :status
    add_index :webhooks, [ :wallet_id, :status ]
  end
end
