BOARD_PILL_UL_CLASSES =
  "nav nav-pills _auto-single-select board-pills flex-column".freeze

BOARD_PILL_LI_CLASSES = "nav-item".freeze

format :html do
  def board_pills items
    list_tag class: BOARD_PILL_UL_CLASSES, items: { class: BOARD_PILL_LI_CLASSES } do
      items
    end
  end

  def board_pill_items data, breadcrumb
    data.map do |text, field, extra_opts|
      opts = board_pill_item_opts breadcrumb, extra_opts, text
      mark = opts.delete(:mark) == :absolute ? field : [card, field]
      link_to_card mark, text, opts
    end
  end

  def board_pill_item_opts breadcrumb, extra_opts, text
    opts = board_link_opts.merge("data-bs-toggle": "pill")
    opts.merge! breadcrumb_data(breadcrumb)

    if extra_opts
      classes = extra_opts.delete :class
      add_class opts, classes if classes
      opts.deep_merge! extra_opts
    end
    opts["data-cy"] = "#{text.to_name.key}-pill"
    add_class opts, "nav-link"
    opts
  end

  def board_pill_sections tab_name
    wrap_with :ul, class: BOARD_PILL_UL_CLASSES do
      yield.map { |args| board_pill_section(tab_name, *args) }
    end
  end

  def board_pill_section tab_name, title, items
    wrap_with(:h6, title, class: "ms-1 mt-3") +
      wrap_each_with(:li, class: BOARD_PILL_LI_CLASSES) do
        board_pill_items(items, tab_name)
      end.html_safe
  end
end
