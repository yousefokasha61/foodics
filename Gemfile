source "https://rubygems.org"

gem "rails", "~> 8.0.4"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "sidekiq", "~> 8.1"
gem "redis", "~> 5.0"
gem "nokogiri", "~> 1.16"

# dry-rb gems
gem "dry-monads", "~> 1.6"
gem "dry-validation", "~> 1.10"
gem "dry-struct", "~> 1.6"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "dotenv-rails"
end

group :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "database_cleaner-active_record"
end
