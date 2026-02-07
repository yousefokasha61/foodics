# Create test wallets
wallets = [
  { name: "John Doe", account_number: "SA6980000204608016212908", balance_cents: 100_000 },
  { name: "Jane Smith", account_number: "SA6980000204608016211111", balance_cents: 250_000 },
  { name: "Acme Corp", account_number: "SA6980000204608016213333", balance_cents: 1_000_000 }
]

wallets.each do |wallet_data|
  Wallet.find_or_create_by!(account_number: wallet_data[:account_number]) do |wallet|
    wallet.name = wallet_data[:name]
    wallet.balance_cents = wallet_data[:balance_cents]
  end
end

puts "Created #{Wallet.count} wallets"
