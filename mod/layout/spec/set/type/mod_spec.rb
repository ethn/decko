RSpec.describe Card::Set::Mod::Type do
  include_examples "mod admin config", :mod_layout, %i[layout head], nil,
                   [["Styling", %i[layout_type]]]

  specify "admin view" do
    expect(render_card(:admin, :mod_layout)).to have_tag :h3, text: "Settings"
  end
end
