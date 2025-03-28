require "htmlentities"

class Cardname
  # some useful variants of card names
  module Variants
    # URI-friendly version of name. retains case, underscores for space
    # @return [String]
    def url_key
      part_names.map do |part_name|
        stripped = part_name.decoded.gsub(/[^#{OK4KEY_RE}]+/, " ").strip
        stripped.gsub(/[\s_]+/, "_")
      end * self.class.joint
    end

    # safe to be used in HTML as id ('*' and '+' are not allowed),
    # but the key is no longer unique.
    # For example "A-XB" and "A+*B" have the same safe_key
    # @return [String]
    def safe_key
      key.tr("*", "X").tr self.class.joint, "-"
    end

    # HTML Entities decoded
    # @return [String]
    def decoded
      @decoded ||= s.index("&") ? HTMLEntities.new.decode(s) : s
    end

    # contextual elements removed
    # @return [String]
    def stripped
      s.gsub(Contextual::RELATIVE_REGEXP, "").to_name
    end

    def fully_stripped
      stripped.parts.reject(&:blank?).cardname
    end

    private

    def uninflect_method
      self.class.uninflect
    end

    def stabilize?
      self.class.stabilize
    end

    # Sometimes the core rule "the key's key must be itself" (called "stable" below)
    # is violated. For example,  it fails with singularize as uninflect method
    # for Matthias -> Matthia -> Matthium
    # Usually that means the name is a proper noun and not a plural.
    # You can choose between two solutions:
    # 1. don't uninflect if the uninflected key is not stable (stabilize = false)
    # 2. uninflect until the key is stable (stabilize = true)
    def stable_key name
      key_one = name.send uninflect_method
      key_two = key_one.send uninflect_method
      return key_one unless key_one != key_two

      stabilize? ? stable_key(key_two) : name
    end
  end
end
