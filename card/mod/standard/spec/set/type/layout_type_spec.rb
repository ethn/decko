# -*- encoding : utf-8 -*-

TMP_LAYOUT = %(
  <body class="wrong-sidebar">
    {{_main|bar}}
  </body>
).freeze

describe Card::Set::Type::LayoutType do
  it "includes Html card methods" do
    expect(Card.new(type: "Layout").clean_html?).to be_falsey
  end

  it "doesn't render main nest" do
    expect_view(:core, card: "Default Layout").to have_tag :pre do
      without_tag "div#main"
    end
  end

  it "takes effect immediately when content changed" do
    layout = Card["Default Layout"]
    expect(format_subject.show(nil, {})).to match(/right-sidebar/)
    Card::Auth.as_bot { layout.update_attributes! content: TMP_LAYOUT }
    expect(format_subject.show(nil, {})).to match(/wrong-sidebar.*bar-view/m)
  end
end
