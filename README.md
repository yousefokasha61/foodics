# Foodics Pay

A Rails API for processing bank webhooks and generating payment transfer requests.

## What This Does

Two main things:

1. **Receiving Money** - Banks send us webhooks when money comes in. We parse different bank formats, store the transactions, and update wallet balances.

2. **Sending Money** - When you want to transfer money out, we generate the XML that banks expect.

## Quick Start

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Start Redis (needed for ingestion control)
redis-server

# Run the server
bin/rails server

# Or run everything with Docker
docker-compose up
```

## API Endpoints

### Receive Webhook

```
POST /api/v1/pay/webhook
```

Headers:
- `X-Wallet-ID` - which wallet this payment is for
- `X-Bank` - either `FOODICS` or `ACME`

Body is plain text in the bank's format (see below).

### Create Transfer

```
POST /api/v1/pay/transfers/:wallet_id
Content-Type: application/json

{
  "receiver": {
    "bank_code": "FDCSSARI",
    "account_number": "SA6980000204608016211111",
    "beneficiary_name": "Jane Doe"
  },
  "amount": 177.39,
  "currency": "SAR",
  "notes": ["Invoice #123", "March payment"],
  "payment_type": 421,
  "charge_details": "RB"
}
```

Only `receiver` and `amount` are required. The rest have sensible defaults (SAR currency, payment type 99, charge details SHA).

Returns XML that you'd send to the bank.

### Ingestion Control

Sometimes you need to pause webhook processing (deployments, maintenance, whatever). The webhooks still get saved, they just don't get processed until you turn it back on.

```
GET  /api/v1/admin/ingestion        # Check status
PATCH /api/v1/admin/ingestion       # { "enabled": false } to pause
```

When you re-enable, all the pending webhooks get queued up automatically.

## Bank Webhook Formats

### Foodics Bank

```
20250615156,50#202506159000001#note/debt payment/internal_ref/A462
```

That's: `YYYYMMDD` + amount (European format with comma) + `#` + reference + `#` + key/value pairs separated by `/`

### Acme Bank

```
156,50//202506159000001//20250615
```

Simpler: amount + `//` + reference + `//` + date

## How It Works

### Webhook Processing

1. Webhook comes in, we save it immediately (never lose data)
2. If ingestion is enabled, we queue a background job
3. Job parses the payload, creates transactions, updates balance
4. Duplicate transactions are silently ignored (idempotency via unique index on bank+reference)

The parsing happens in background jobs so the webhook endpoint responds fast. Banks don't like waiting.

### Idempotency

Banks sometimes send the same webhook twice. We handle this with a unique constraint on `(bank, reference)` in the transactions table. If you try to insert a duplicate, Postgres just skips it. The wallet balance only gets updated for actually-inserted transactions.

### Error Handling

Using dry-monads throughout. Everything returns `Success` or `Failure`, no exceptions flying around in business logic. Makes the code easier to follow:

```ruby
def create(params)
  contract.call(params).bind do |validated|
    wallet_repository.find_one.bind do |wallet|
      # ... and so on
    end
  end
end
```

Controllers just pattern match on the result:

```ruby
case result
in Success(data)
  render json: data
in Failure(error)
  render json: error.to_h, status: error.http_status_code
end
```

## Project Structure

```
app/
├── controllers/api/v1/
│   ├── pay/
│   │   ├── webhook_controller.rb    # Receives webhooks
│   │   └── transfers_controller.rb  # Generates transfer XML
│   └── admin/
│       └── ingestions_controller.rb # Pause/resume processing
├── jobs/
│   └── process_webhook_job.rb       # Background processing
├── lib/
│   ├── api/error.rb                 # Standardized error responses
│   └── pay/
│       ├── parser/                  # Bank-specific parsers
│       ├── payment/                 # XML builder stuff
│       ├── webhook/                 # Webhook contracts, repos
│       └── wallet/                  # Wallet repository
├── models/
│   ├── wallet.rb
│   ├── webhook.rb
│   └── transaction.rb
└── public/pay/
    ├── webhook/service.rb           # Main webhook logic
    └── payment/service.rb           # Main payment logic
```

The `app/lib` vs `app/public` split: `public` contains the service classes that controllers call, `lib` has the internal bits (parsers, builders, repos).

## Database Schema

Three tables:

**wallets** - The accounts. Has `account_number` and `balance_cents`.

**webhooks** - Raw webhook data. We keep everything, even if parsing fails. Has `status` (PENDING/PROCESSING/PROCESSED/FAILED) and `processing_errors` for debugging.

**transactions** - Parsed transactions. Linked to both wallet and webhook. The `(bank, reference)` unique index handles idempotency.

## Testing

```bash
bundle exec rspec
```

There's unit tests for parsers and XML builder, integration tests for the API endpoints, and a performance test that processes 1000 transactions to make sure parsing doesn't get slow.

## Tech Stack

- Rails 8 (API mode)
- PostgreSQL
- Redis (for ingestion state)
- Sidekiq (background jobs)
- dry-rb gems (monads, validation, structs)
- Nokogiri (XML generation)

## Design Decisions

**Why headers for wallet/bank identification?**

Went back and forth on this. Could've been path params or query params. Headers felt cleaner since the webhook body is plain text from the bank - mixing our params into the URL felt messy. Plus it's similar to how payment processors does webhook verification with signature headers.

**Why Redis for ingestion control?**

Simple key-value check that needs to be fast and shared across all workers. Redis fits perfectly. Could've used the database but that's slower and more complex.

**Why dry-monads?**

Exceptions are fine for truly exceptional things, but validation errors and "wallet not found" aren't exceptional - they're expected. Returning `Success`/`Failure` makes the control flow explicit. No more wondering "does this method raise or return nil?"

**Why Nokogiri for XML?**

It's the standard. Considered just string interpolation but that's asking for encoding bugs. Nokogiri handles all the edge cases.

**Why store raw webhooks?**

Debugging. When something goes wrong (and it will), having the exact payload the bank sent is invaluable. Storage is cheap, trust is expensive.

## CI

GitHub Actions runs on every PR:
- RSpec tests (with Postgres and Redis services)
- RuboCop linting
- Brakeman security scanning

Check `.github/workflows/ci.yml` for details.
