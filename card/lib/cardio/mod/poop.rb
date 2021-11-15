module Cardio
  class Mod
    # export data to data directory of mods
    # (list of card attributes)
    # https://docs.google.com/document/d/13K_ynFwfpHwc3t5gnLeAkZJZHco1wK063nJNYwU8qfc/edit#
    class Poop
      def initialize **args
        @mod = args[:mod]
        @name = args[:name]
        @cql = args[:cql]
        @env = args[:env] || Rails.env
        @items = args[:items]
        @field_tags = args[:field_tags]
      end

      # @return [Array <Hash>]
      def new_data
        @new_data ||= cards.map { |c| c.export_hash field_tags: field_tag_marks }
      end

      def field_tag_marks
        @field_tag_marks ||= @field_tags.to_s.split(",").map do |mark|
          mark.strip.cardname.codename_or_string
        end
      end

      # @return [String] -- MOD_DIR/data/ENVIRONMENT.yml
      def filename
        @filename ||= File.join mod_path, "#{@env}.yml"
      end

      # if output mod given,
      def out
        Card::Cache.reset_all
        @mod ? dump : puts(new_data.to_yaml.yellow)
        :success
      rescue Card::Error::NotFound => e
        e.message
      rescue JSON::ParserError => e
        e.message
      end

      # write yaml to file
      def dump
        hash = output_hash
        File.write filename, hash.to_yaml
        puts "#{filename} now contains #{hash.size} items".green
      end

      private

      def cards
        if @name
          cards_from_name
        elsif @cql
          Card.search JSON.parse(@cql).reverse_merge(limit: 0)
        else
          raise Card::Error::NotFound, "must specify either name (-n) or CQL (-c)"
        end
      end

      def cards_from_name
        card = main_card
        case @items
        when :only
          card.item_cards
        when true
          [card] + card.item_cards
        else
          [card]
        end
      end

      def main_card
        Card.fetch(@name) || raise(Card::Error::NotFound, "card not found: #{@mod}")
      end

      def output_hash
        if target.present?
          merge_data
          target
        else
          new_data
        end
      end

      def merge_data
        new_data.each do |item|
          if (index = target_index item)
            target[index] = item
          else
            target << item
          end
        end
      end

      def target_index new_item
        target.find_index do |target_item|
          new_code = new_item[:codename]
          (new_code.present? && new_code == target_item[:codename]) ||
            target_item[:name].to_name == new_item[:name].to_name
        end
      end

      def target
        @target ||= old_data
      end

      def old_data
        return nil unless File.exist? filename

        YAML.safe_load File.read(filename), [Symbol]
      end

      # @return Path
      def mod_path
        Mod.dirs.subpaths("data")[@mod] ||
          raise(Card::Error::NotFound, "no data directory found for mod: #{@mod}")
      end
    end
  end
end
