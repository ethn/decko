RSpec.describe Cardio::Mod do
  describe "gem_spec" do
    def gem_spec *args
      described_class.send :gem_spec, *args
    end

    it "finds card mods" do
      expect(gem_spec("card-mod-defaults")).to be_a(Gem::Specification)
    end

    it "handles nicknames" do
      expect(gem_spec("defaults")).to be_a(Gem::Specification)
    end

    it "doesn't use nicknames when told not to" do
      expect(gem_spec("defaults", false)).to be_nil
    end
  end

  describe "dependencies" do
    it "finds card mods" do
      expect(described_class.dependencies("card-mod-defaults").map(&:name))
        .to include("card-mod-edit")
    end

    it "doesn't find other gems" do
      expect(described_class.dependencies("card-mod-defaults").map(&:name))
        .not_to include("card")
    end
  end
end
