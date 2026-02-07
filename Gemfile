source "https://rubygems.org"

gem "rails", "~> 8.0.4"
gem "pg", "~> 1.5"
gem "puma", ">= 5.0"
gem "sidekiq", "~> 7.3"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
end
