# Only seed in development
return unless Rails.env.development?

# Create test wallets with fixed IDs for predictable API calls
wallets = [
  { id: 1, name: "John Doe", account_number: "SA6980000204608016212908", balance_cents: 100_000 },
  { id: 2, name: "Jane Smith", account_number: "SA6980000204608016211111", balance_cents: 250_000 },
  { id: 3, name: "Acme Corp", account_number: "SA6980000204608016213333", balance_cents: 1_000_000 }
]

wallets.each do |wallet_data|
  Wallet.where(id: wallet_data[:id]).first_or_create!(wallet_data)
end

ActiveRecord::Base.connection.reset_pk_sequence!("wallets")

puts "Seeded #{Wallet.count} wallets with IDs: #{Wallet.pluck(:id).join(', ')}"
