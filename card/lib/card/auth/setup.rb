class Card
  module Auth
    # singleton methods for managing setup state
    module Setup
      NEEDS_SETUP = "NEEDS_SETUP".freeze

      # app is not totally set up yet
      # @return [true/false]
      def needs_setup?
        if @needs_setup == false || Card.cache.read(NEEDS_SETUP)&.to_s == "false"
          @needs_setup = false
        else
          user_account_count.zero?.tap do |need|
            Card.cache.write NEEDS_SETUP, false unless need
          end
        end
      end

      # for testing setup
      def simulate_setup! mode=true
        Card.cache.delete NEEDS_SETUP
        @needs_setup = nil
        if mode
          @hidden_accounts = user_account_ids
        else
          @hidden_accounts = nil
        end
      end

      def instant_account_activation
        simulate_needs_setup!
        yield
      ensure
        simulate_needs_setup! false
      end

      private

      def user_account_ids
        as_bot { Card.search user_account_cql.merge(return: :id) }
      end

      def user_account_cql
        # every deck starts with two accounts: WagnBot and Anonymous
        { right_id: Card::AccountID, creator_id: ["ne", Card::WagnBotID] }
      end

      def user_account_count
        cql = user_account_cql
        cql[:not] = { id: ["in"].concat(@hidden_accounts) } if @hidden_accounts
        as_bot { Card.count_by_cql cql }
      end
    end
  end
end
