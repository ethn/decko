
basket[:tasks] = {}
basket[:config_title] = {
  basic: "Basic configuration",
  editor: "Editor configuration"
}
# to add an admin task:
#
# basket[:tasks][TASK_NAME] = {
#   irreversible: TRUE/FALSE,
#   execute_policy: -> { TASK_CODE },
#   mod: MODNAME
# }
#
# Then add two lines in the locales containing the link text and the description:

#   MOD_task_TASK_NAME_link_text: LINK_TEXT
#   MOD_task_TASK_NAME_description: DESCRIPTION


Config = Struct.new(:mod, :category, :subcategory, :codename, :roles) do
  # self::SUBCATEGORY_TITLE = basket[:config_title]

  def title
    subcategory ? Card::Set::All::Admin::basket[:config_title][subcategory.to_sym] || subcategory.capitalize :
      Card::Set::All::Admin::basket[:config_title][category.to_sym]  || category.capitalize
  end
end

def mod_cards_with_config
  Card.search(type_id: Card::ModID).select { |mod| mod.admin_config.present? }
end

def create_config_objects mod, category, subcategory=nil, values
  Array.wrap(values).map do |value|
    config = Config.new(mod, category, subcategory, value)
    config.roles = Card::Codename.exist?(config.codename.to_sym) ? Card[config.codename.to_sym].responsible_role : []
    config
  end
end

def responsible_set_card
  Card.fetch([self, :self, :update], new: {})
end

def responsible_role
  responsible_set_card.find_existing_rule_card.item_cards.map(&:codename)
end

def all_configs
  mod_cards_with_config.map(&:admin_config_objects).flatten
end


def all_admin_configs_grouped_by property1, property2=nil
  return admin_config_by_by property1, property2 if property2

  result = Hash.new {|hash, k| hash[k] = [] }
  all_configs.each_with_object(result) do |config, h|
    if property == :roles
      config.roles.each do |role|
        h[role] << config
      end
    else
      h[config.send(property)] << config
    end
  end
end

def config_codenames_grouped_by_title configs
  configs&.group_by { |c| c.title }&.map do |title, configs|
    [title, configs.map { |config | config.codename.to_sym }]
  end
end


format :html do
  def section title, content
    "#{section_title(title)}<p>#{content}</p>"
  end

  def section_title title
    "<h3>#{title}</h3>"
  end

  def list_section title, items, item_view=:bar
    return unless items.present?

    section title, list_section_content(items, item_view)
  end

  def nested_list_section title, grouped_items
    output [
             section_title(title),
             wrap_with(:div, accordion_sections(grouped_items), class: "accordion")
           ]
  end

  def accordion_sections grouped_items
    grouped_items.map do |title, codenames|
      accordion_item(title,
                     subheader: nil,
                     body: list_section_content(codenames),
                     open: false,
                     context: title.hash)

    end.join " "
  end

  def list_section_content items, item_view=:bar
    items&.map do |card|
      nest card, view: item_view
    end&.join(" ")
  end
end

private


def admin_config_by_by property1, property2
  result = Hash.new {|hash, k| hash[k] = Hash.new {|hash2, k2| hash2[k2] = [] } }
  all_configs.each_with_object(result) do |config, h|
    if property1 == :roles
      config.roles.each do |role|
        h[role][config.send(property2)] << config
      end
    elsif property2 == :roles
      config.roles.each do |role|
        h[config.send(property1)][role] << config
      end
    else
      h[config.send(property1)][config.send(property2)] << config
    end
  end
end