class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :wallet, null: false, foreign_key: true
      t.references :webhook, null: false, foreign_key: true
      t.string :bank, null: false
      t.string :reference, null: false
      t.bigint :amount_cents, null: false
      t.date :transaction_date, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :transactions, [ :bank, :reference ], unique: true
    add_index :transactions, :transaction_date
    add_index :transactions, [ :wallet_id, :transaction_date ]
  end
end
