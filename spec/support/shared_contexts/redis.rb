# frozen_string_literal: true

RSpec.shared_context "with redis" do
  before do
    REDIS.flushdb
  end

  after do
    REDIS.flushdb
  end
end
