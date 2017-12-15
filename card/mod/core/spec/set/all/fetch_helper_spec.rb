# -*- encoding : utf-8 -*-

RSpec.describe Card::Set::All::FetchHelper do
  let :retrieve do
    Card.send(:retrieve_existing, mark, {}).map(&:class)
  end

  let :retrieve_from_trash do
    Card.send(:retrieve_existing, mark, look_in_trash: true).map(&:class)
  end

  describe "retrieve_existing" do
    let(:mark) { "A".to_name }
    let(:opts) { {} }

    it "looks for card in both cache and database" do
      expect(Card).to receive(:retrieve_from_db).with(:key, "a", nil)
      retrieve
    end

    it "doesn't look in db for real cards already in cache" do
      Card.cache.write "a", Card["B"]
      expect(Card).not_to receive(:retrieve_from_db)
      retrieve
    end

    it "doesn't look in db for new cards already in cache" do
      Card.cache.write "a", Card.new
      expect(Card).not_to receive(:retrieve_from_db)
      retrieve
    end

    it "looks in db for new cards already in cache if 'look_in_trash' option used" do
      Card.cache.write "a", Card.new
      expect(Card).to receive(:retrieve_from_db).with(:key, "a", true)
      retrieve_from_trash
    end
  end
end
