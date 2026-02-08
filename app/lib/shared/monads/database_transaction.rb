# frozen_string_literal: true

module Shared
  module Monads
    module DatabaseTransaction
      include Dry::Monads[:result]

      module_function

      # Wraps the given block in a database transaction. Transaction is rolled
      # back if an exception is thrown by the block, or if the block returns a
      # Failure. Shares signature with {ActiveRecord::Base.transaction}.
      #
      # @see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-transaction ActiveRecord::Base.transaction
      # @param requires_new [Boolean] if no transaction is open, this has no
      #   effect, a transaction will always be created. If a transaction is
      #   already open, this determines whether a nested transaction will be
      #   created using SAVEPOINTS.
      # @param isolation [Symbol] determines the isolation level to be set for
      #   the transaction
      # @param joinable [Boolean] whether a nested transaction without
      #   requires_new set can be added to this transaction.
      # @param block [Block] code to be run within the transaction
      #
      # @yieldreturn [T1] the type returned by the given block
      # @return [T1] returns whatever the return value of the block was
      #
      # @example Successful operation
      #   transaction do              # BEGIN
      #     User.create(name: 'Andy')   # INSERT ...
      #     Success(:created)
      #   end                         # COMMIT
      #
      # @example Return a Failure
      #   transaction do              # BEGIN
      #     User.create(name: 'Andy')   # INSERT ...
      #     Failure(:record_invalid)
      #   end                         # ROLLBACK
      #
      # @example Raise an exception
      #   transaction do                  # BEGIN
      #     u = User.create(name: 'Andy')   # INSERT ...
      #     raise RecordInvalid, u
      #   end                             # ROLLBACK
      #
      # @example Nested Transaction
      #   transaction do                       # BEGIN
      #     u = User.create(name: 'Andy')        # INSERT ...
      #     transaction(requires_new: true) do   # SAVEPOINT savepoint_1
      #       User.update(u, name: 'Not Andy')     # UPDATE ...
      #       Failure(:record_invalid)
      #     end                                  # ROLLBACK TO SAVEPOINT savepoint_1
      #     Success(:created)
      #   end                                  # COMMIT
      #
      # @example Nested Transaction, chained failures
      #   transaction do                       # BEGIN
      #     u = User.create(name: 'Andy')        # INSERT ...
      #     transaction(requires_new: true) do   # SAVEPOINT savepoint_1
      #       User.update(u, name: 'Not Andy')     # UPDATE ...
      #       Failure(:record_invalid)
      #     end                                  # ROLLBACK TO SAVEPOINT savepoint_1
      #   end                                  # ROLLBACK
      #
      def transaction(**kwargs)
        ActiveRecord::Base.transaction(**kwargs) do
          result = yield

          if result.is_a?(Dry::Monads::Result) && result.failure?
            # use Exception to rollback transaction and wrap Failure
            rollback_with(result)
          else
            result
          end
        end
      rescue ResultWrapperException => e
        # unwrap Failure from Exception
        e.result
      end

      def rollback_with(result)
        raise ResultWrapperException, result
      end

      class ResultWrapperException < StandardError
        attr_accessor :result

        def initialize(result)
          @result = result
          error = result.failure
          super("Shared::Monads::DatabaseTransaction rolled back: #{error.inspect}")
        end
      end
      private_constant :ResultWrapperException
    end
  end
end
