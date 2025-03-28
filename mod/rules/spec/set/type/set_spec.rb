# -*- encoding : utf-8 -*-

RSpec.describe Card::Set::Type::Set do
  check_views_for_errors

  def card_subject
    Card.fetch "User+*type"
  end

  describe "#compound_only?" do
    it "identifies sets that only apply to plus cards", :aggregate_failures do
      expect(Card.fetch("*all")).not_to be_compound_only
      expect(Card.fetch("*all plus")).to be_compound_only
      expect(Card.fetch("Book+*type")).not_to be_compound_only
      expect(Card.fetch("*to+*right")).to be_compound_only
      expect(Card.fetch("Book+*to+*type plus right"))
        .to be_compound_only
    end
  end

  describe "#inheritable?" do
    it "identifies sets that can inherit rules", :aggregate_failures do
      expect(Card.fetch("A+*self")).not_to be_inheritable
      expect(Card.fetch("A+B+*self")).to be_inheritable
      expect(Card.fetch("Book+*to+*type plus right")).to be_inheritable
      expect(Card.fetch("Book+*type")).not_to be_inheritable
      expect(Card.fetch("*to+*right")).to be_inheritable
      expect(Card.fetch("*all plus")).to be_inheritable
      expect(Card.fetch("*all")).not_to be_inheritable
    end
  end

  describe "structure rule content" do
    let :nest_syntax do
      "_left+test_another_card|content|content;structure:test_another_card_structure"
    end

    let :structure_rule do
      Card::Auth.as_bot do
        Card.create! name: "test_card+*right+*structure",
                     type_id: Card::HtmlID,
                     content: "{{#{nest_syntax}}}"
      end
    end

    let :nested_card do
      Card::Auth.as_bot do
        Card.create! name: "test_another_card+*right+*structure",
                     type_id: Card::SearchTypeID,
                     content: ' {"type":"RichText","left":"_1"}'
      end
    end

    it "renders nest as a link to template editor of nested card's +*right set" do
      expect(structure_rule.format.render_open)
        .to have_tag("a.slotter") do
        with_text(/#{Regexp.escape nest_syntax}/)
      end
    end

    it "produces template editor with close link within large brackets" do
      set_card = nested_card.fetch :right
      expect(set_card.format.render(:template_link)).to have_tag("div.card-slot") do
        with_text(/^\{\{.+\}\}$/)
        with_tag "a", "modal_nest_rules"
      end
    end
  end

  describe "#nest_editor_field_related_settings" do
    it "finds settings based on set", :as_bot do
      create ["characters", :right, :input_type], content: "select"
      create ["characters", :right, :default], type_id: Card::ListID
      card = Card.new name: "RichText+characters+*type plus right"
      expect(card.nest_editor_field_related_settings)
        .to eq %i[default help input_type content_options content_option_view]
    end
  end
end
