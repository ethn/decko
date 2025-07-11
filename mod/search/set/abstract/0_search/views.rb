format do
  view :search_count, cache: :never do
    search_with_params.to_s
  end

  view :search_error, cache: :never do
    %(#{search_with_params.class} :: #{search_with_params.message} :: #{card.content})
  end

  view :card_list, cache: :never do
    with_results do
      search_with_params.map do |item_card|
        nest_item item_card
      end.join "\n"
    end
  end

  view :no_search_results do
    "no results"
  end

  def with_results
    search_with_params.empty? ? render_no_search_results : yield
  end

  def item_cards
    search_with_params
  end
end

format :json do
  # NOCACHE because paging_urls is uncacheable hash and thus not safe to merge
  view :molecule, cache: :never do
    molecule.merge render_paging_urls
  end

  # TODO: design better autocomplete API
  view :name_complete, cache: :never do
    format_json_search { complete_search limit: AUTOCOMPLETE_LIMIT }
  end

  view :name_match, cache: :never do
    format_json_search { complete_or_match_search limit: AUTOCOMPLETE_LIMIT }
  end

  def complete_or_match_search limit: AUTOCOMPLETE_LIMIT, start_only: false,
                               additional_cql: {}
    starts_with = complete_search limit: limit, additional_cql: additional_cql
    return starts_with if start_only

    remaining_slots = limit - starts_with.size
    return starts_with if remaining_slots.zero?

    starts_with + match_search(not_names: starts_with, limit: remaining_slots,
                               additional_cql: additional_cql)
  end

  def complete_search limit: AUTOCOMPLETE_LIMIT, additional_cql: {}
    card.search name_cql(limit).merge(complete_cql).merge(additional_cql)
  end

  def match_search limit: AUTOCOMPLETE_LIMIT, not_names: [], additional_cql: {}
    return [] unless term_param.present?

    card.search name_cql(limit).merge(match_cql(not_names)).merge(additional_cql)
  end

  private

  def name_cql limit
    { limit: limit, sort_by: "name", return: "name" }
  end

  def complete_cql
    { complete: term_param.to_s }
  end

  def match_cql not_names
    cql = { name_match: term_param }
    cql[:name] = ["not in"] + not_names if not_names.any?
    cql
  end

  def format_json_search
    results = yield
    return results if item_view_options[:view]&.to_sym == :name

    results.map do |item_card|
      nest_item item_card
    end.to_json
  end
end

format :data do
  view :card_list do
    search_with_params.map do |item_card|
      nest_item item_card
    end
  end
end

format :csv do
  view :body do
    search_with_params.map { |item_card| nest item_card }
  end
end

format :html do
  view :card_list, cache: :never do
    klasses = "card-list card-list-#{item_view_options[:view]} search-result-list"
    search_result_list(klasses) do
      search_with_params.map do |item_card|
        card_list_item item_card
      end
    end
  end

  view :checkbox_list, cache: :never do
    search_result_list "_search-checkbox-list pe-2" do
      search_with_params.map do |item_card|
        checkbox_item item_card
      end
    end
  end

  view :no_search_results do
    wrap_with :div, "", class: "search-no-results"
  end

  private

  def card_list_item item_card
    nest_item item_card, size: voo.size do |rendered, item_view|
      %(<div class="search-result-item item-#{item_view}">#{rendered}</div>)
    end
  end

  def search_result_list klass, &block
    with_results { with_paging { wrap_with :div, class: klass, &block } }
  end

  def checkbox_item item_card
    subformat(item_card).wrap do
      haml :checkbox_item, unique_id: unique_id, item_card: item_card
    end
  end
end
