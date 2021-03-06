# -*- encoding : utf-8 -*-

class Card
  class Content
    module Chunk
      class Reference < Abstract
        attr_writer :referee_name
        attr_accessor :name

        def referee_name
          return if name.nil?

          @referee_name ||= referee_raw_name
          @referee_name = @referee_name.absolute_name card.name
        rescue Card::Error::NotFound
          # do not break on missing id/codename references.
        end

        def referee_raw_name
          Name[render_obj(name)]
        end

        def referee_card
          @referee_card ||= referee_name && Card.fetch(referee_name)
        end

        private

        def replace_name_reference old_name, new_name
          @referee_card = nil
          @referee_name = nil
          if name.is_a? Content
            name.find_chunks(:Reference).each do |chunk|
              chunk.replace_reference old_name, new_name
            end
          else
            @name = name.to_name.swap old_name, new_name
          end
        end

        def render_obj raw
          return raw unless format && raw.is_a?(Content)

          format.process_content raw
        end
      end
    end
  end
end
