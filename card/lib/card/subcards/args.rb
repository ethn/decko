class Card
  class Subcards
    # Handling shared subcard args processing
    module Args
      def extract_subcard_args! args
        safe_subcard_args args do |subcards|
          extract_explicit_subfields subcards, args
          extract_implicit_subfields subcards, args
        end
      end

      private

      # FIXME: the following should be handled before it gets this far
      def safe_subcard_args args
        subcards = args.delete(:subcards) || {}
        yield subcards
        subcards.try(:to_unsafe_h) || subcards
      end

      def extract_explicit_subfields subcards, args
        return unless (subfields = args.delete :subfields)

        subfields.each_pair do |key, value|
          subcards[normalize_subfield_key(key)] = value
        end
      end

      # ensure a leading '+'
      def normalize_subfield_key key
        key = Card::Codename.name(key) if key.is_a?(Symbol) && Card::Codename.exist?(key)
        key.to_name.prepend_joint
      end

      def extract_implicit_subfields subcards, args
        args.each_key do |key|
          subcards[key.to_s] = args.delete(key) if key.to_s.match?(/^\+/)
        end
      end
    end
  end
end
