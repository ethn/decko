require "timecop"
# require "pry"

ENV["STORE_CODED_FILES"] = "true"

module Cardio
  class Mod
    # import data from data directory of mods
    # (list of card attributes)
    # https://docs.google.com/document/d/13K_ynFwfpHwc3t5gnLeAkZJZHco1wK063nJNYwU8qfc/edit#
    class Eat
      include Edibles

      def initialize mod: nil, podtype: nil, user: nil, verbose: nil, name: nil
        @mod = mod
        @pod_type = podtype&.to_sym
        @name = name
        @user_id = user&.card_id
        @verbose = !verbose.nil?
      end

      def run
        handle_up do
          edibles.each do |edible|
            track edible do
              current_user edible.delete(:user)
              time_machine edible.delete(:time) do
                Card.ensure! edible
              end
            end
          end
        end
      end

      private

      # if output mod given,
      def handle_up &block
        Card::Cache.reset_all
        Card::Mailer.perform_deliveries = false
        Card::Auth.as_bot(&block)
        :success
      rescue StandardError => e
        e.message
      end

      def track edible
        rescuing edible do
          # n = edible[:name]
          # binding.pry if (n.is_a? Array) && n.first.to_s == "main_menu"
          # puts "eating: #{edible}" if @verbose
          card = yield
          puts "eaten: #{card.name}".cyan if @verbose
        end
      end

      def rescuing edible
        yield
      rescue StandardError => e
        puts edible
        puts e.message.red
        puts e.backtrace[0..10].join("\n") if @verbose
      end

      def current_user item_user
        Card::Auth.current_id = item_user&.card_id || @user_id || Card::DeckoBotID
      end

      def time_machine value, &block
        return yield unless value.present?

        Timecop.freeze Time.at(time_integer(value)), &block
      end

      def time_integer value
        case value
        when /^[+-]\d+$/
          # plus or minus an integer (safe to eval)
          eval "#{Time.now.to_i} #{value}", # 1741296981 +1  (e.g.)
               binding, __FILE__, __LINE__ - 1
        when Integer
          value
        else
          raise TypeError, "invalid time value: #{value}. accepts int, +int, and -int"
        end
      end
    end
  end
end
