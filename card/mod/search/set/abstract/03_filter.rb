include_set Abstract::FilterFormHelper
include_set Abstract::Utility

def filter_class
  Card::FilterQuery
end

def filter_and_sort_wql
  sort? ? filter_wql.merge(sort_wql) : filter_wql
end

def filter_wql
  return {} if filter_hash.empty?

  filter_wql_from_params
end

# separate method is needed for tests
def filter_wql_from_params
  filter_class.new(filter_keys_with_values, blocked_id_wql).to_wql
end

def sort_wql
  sort? ? sort_hash : {}
end

def sort?
  true
end

def current_sort
  sort_param || default_sort_option
end

def blocked_id_wql
  not_ids = filter_param :not_ids
  not_ids.present? ? { id: ["not in", not_ids.split(",")] } : {}
end

# all filter keys in the order they were selected
def all_filter_keys
  @all_filter_keys ||= filter_keys_from_params | filter_keys
end

def filter_keys
  [:name]
end

def filter_keys_from_params
  filter_hash.keys.map(&:to_sym) - [:not_ids]
end

format :html do
  delegate :filter_hash, to: :card

  def filter_fields slot_selector: nil, sort_field: nil
    form_args = { action: filter_action_path, class: "slotter" }
    form_args["data-slot-selector"] = slot_selector if slot_selector
    filter_form filter_form_data, sort_field, form_args
  end

  def filter_form_data
    all_filter_keys.each_with_object({}) do |cat, h|
      h[cat] = { label: filter_label(cat),
                 input_field: _render("filter_#{cat}_formgroup"),
                 active: active_filter?(cat),
                 default: default_filter?(cat) }
    end
  end

  def active_filter? field
    filter_hash.present? ? filter_hash.key?(field) : default_filter?(field)
  end

  def default_filter? field
    card.default_filter_option.key?(field)
  end

  def filter_label field
    return "Keyword" if field.to_sym == :name

    filter_label_from_method(field) || filter_label_from_name(field)
  end

  def filter_label_from_method field
    try "#{field}_filter_label"
  end

  def filter_label_from_name field
    Card.fetch_name(field) { field.to_s.capitalize }
  end

  def filter_action_path
    path
  end

  view :filter_form, cache: :never do
    filter_fields slot_selector: "._filter-result-slot",
                  sort_field: _render(:sort_formgroup)
  end

  # @param data [Hash] the filter categories. The hash needs for every category
  #   a hash with a label and a input_field entry.
  def filter_form data={}, sort_input_field=nil, form_args={}
    haml :filter_form, categories: data,
                       sort_input_field: sort_input_field,
                       form_args: form_args
  end

  def sort_options
    {
      "Alphabetical": :name,
      "Recently Updated": :updated_at
    }
  end

  view :sort_formgroup, cache: :never do
    select_tag "sort",
               options_for_select(sort_options, card.current_sort),
               class: "pointer-select _filter-sort form-control",
               "data-minimum-results-for-search": "Infinity"
  end
end

def default_sort_option
  wql_from_content[:sort]
end
