class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.string :name, null: false
      t.string :account_number, null: false
      t.bigint :balance_cents, null: false, default: 0

      t.timestamps
    end

    add_index :wallets, :account_number, unique: true
  end
end
