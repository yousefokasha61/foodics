# frozen_string_literal: true

require "dry-struct"

module Api
  class Error < Dry::Struct
    module Types
      include Dry.Types()
    end

    ACCEPTABLE_CODES = {
      "BAD_REQUEST" => 400,
      "UNAUTHORIZED" => 401,
      "FORBIDDEN" => 403,
      "NOT_FOUND" => 404,
      "METHOD_NOT_ALLOWED" => 405,
      "NOT_ACCEPTABLE" => 406,
      "CONFLICT" => 409,
      "CONTENT_TOO_LARGE" => 413,
      "UNPROCESSABLE_ENTITY" => 422,
      "TOO_MANY_REQUESTS" => 429,
      "INTERNAL_SERVER_ERROR" => 500,
      "SERVICE_UNAVAILABLE" => 503
    }.freeze

    ACCEPTABLE_DETAIL_CODES = %w[
            CONFLICT
            INVALID_PROPERTY
            MISSING_REQUIRED_PROPERTY
            NOT_FOUND
          ].freeze

    # @return [String] the code for this error. See ::ACCEPTABLE_CODES for possible values.
    attribute :code, Types::String.enum(*ACCEPTABLE_CODES.keys)
    # @return [String] the message for this error
    attribute :message, Types::String
    # @return [Integer] the http status code relevant for this error.
    attribute :http_status_code, Types::Integer.enum(*ACCEPTABLE_CODES.values)

    # @return [Array] an optional array of details for this error
    attribute :details, Types::Array.default(EMPTY_ARRAY) do
      # @return [String] the code for this error. See ::ALLOWED_DETAIL_CODES for possible values.
      attribute :reason_code, Types::String.enum(*ACCEPTABLE_DETAIL_CODES)
      # @return [String] the message for this error. Some
      #   service-to-service communication is unable to generate this field
      #   because it does not know how to translate the attribute name.
      #   These cases provide stem_message instead.
      attribute? :message, Types::String
      # @return [String] the stem message for this error. Suitable for use by ActiveRecord errors.
      attribute? :stem_message, Types::String
      # @return [String] the (optional) source for this error
      attribute? :source, Types::Coercible::String
    end

    # @return [Hash] a serialized version of the struct. It does not include http_status_code
    #   because it is not typically required in serialization.
    #
    # @example Usage of entity for a caller in a controller:
    #    match ChangeOrders::Service.new.call do |m|
    #      m.success { |entity| render json: entity.to_h }
    #      m.failure { |error| render json: entity.to_h, status: entity.http_status_code  }
    #    end
    def to_h
      super.except(:http_status_code).tap do |hash|
        if hash[:details].present?
          hash[:details] = hash[:details].map { |d| d.except(:stem_message) }
        end
      end
    end

    def to_exception
      WrapperError.new(self)
    end

    delegate :to_json, :as_json, to: :to_h

    class WrapperError < StandardError
      def initialize(api_error)
        @api_error = api_error
        super(api_error.inspect)
      end

      attr_reader :api_error

      def bugsnag_meta_data
        { api_error: api_error.to_h }
      end
    end

    class << self
      # @return [::Financials::Public::Api::Error] builds a new object, filling a http_status_code
      def build(attributes)
        new(attributes.merge(http_status_code: ACCEPTABLE_CODES[attributes[:code]]))
      end

      def bad_request(message)
        build(code: "BAD_REQUEST", message:)
      end

      def not_found(message)
        build(code: "NOT_FOUND", message:)
      end

      def internal_server_error(message)
        build(code: "INTERNAL_SERVER_ERROR", message:)
      end

      def forbidden(message)
        build(code: "FORBIDDEN", message:)
      end

      def unprocessable_entity(message)
        build(code: "UNPROCESSABLE_ENTITY", message:)
      end

      def content_too_large(message)
        build(code: "CONTENT_TOO_LARGE", message:)
      end

      private :new
    end
  end
end
