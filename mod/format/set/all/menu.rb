format :html do
  view :menu, denial: :blank, unknown: true do
    return "" if card.unknown?

    wrap_with :div, class: "card-menu #{menu_link_classes}" do
      [render_help_link,
       menu_link,
       (voo.show?(:bridge_link) ? bridge_link(false) : nil)]
    end
  end

  def menu_link
    case voo.edit
    when :inline
      edit_inline_link
    when :full
      edit_in_bridge_link
    else # :standard
      edit_link
    end
  end

  def edit_view
    case voo.edit
    when :inline
      :edit_inline
    when :full
      :edit
    else # :standard
      edit_link
    end
  end

  view :edit_link, unknown: true, denial: :blank do
    edit_link edit_link_view
  end

  def edit_link_view
    :edit
  end

  view :full_page_link do
    full_page_link
  end

  view :bridge_link, unknown: true do
    bridge_link
  end

  def bridge_link in_modal=true
    opts = { class: "bridge-link" }
    if in_modal
      # add_class opts, "close"
      opts["data-slotter-mode"] = "modal-replace"
    end
    link_to_view :bridge, material_icon(:more_horiz), opts
  end

  # no caching because help_text view doesn't cache, and we can't have a
  # stub in the data-content attribute or it will get html escaped.
  view :help_link, cache: :never, unknown: true do
    help_link render_help_text, help_title
  end

  def help_link text=nil, title=nil
    opts = help_popover_opts text, title
    add_class opts, "_card-menu-popover"
    link_to help_icon, opts
  end

  def help_popover_opts text=nil, title=nil
    text ||= render_help_text
    opts = { "data-placement": :left, class: "help-link" }
    popover_opts text, title, opts
  end

  def help_icon
    material_icon("help")
  end

  def help_title
    "#{name_parts_links} (#{render_type}) #{full_page_link unless card.simple?}"
  end

  def name_parts_links
    card.name.parts.map do |part|
      link_to_card part
    end.join Card::Name.joint
  end

  def full_page_link
    link_to_card full_page_card, full_page_icon, class: classy("full-page-link")
  end

  def full_page_card
    card
  end

  def edit_in_bridge_link opts={}
    edit_link :bridge, opts
  end

  def edit_link view=:edit, opts={}
    link_to_view view, opts.delete(:link_text) || menu_icon,
                 edit_link_opts(opts.reverse_merge(modal: :lg))
  end

  # @param modal [Symbol] modal size
  def edit_link_opts modal: nil
    opts = { class: classy("edit-link") }
    if modal
      opts[:"data-slotter-mode"] = "modal"
      opts[:"data-modal-class"] = "modal-#{modal}"
    end
    opts
  end

  def menu_link_classes
    "nodblclick#{show_view?(:hover_link) ? ' _show-on-hover' : ''}"
  end

  def menu_icon
    material_icon "edit"
  end

  def full_page_icon
    icon_tag :open_in_new
  end
end
