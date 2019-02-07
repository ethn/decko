format :html do
  def image_card
    @image_card ||= card.fetch(trait: :image)
  end

  def image_src opts
    return "" unless image_card
    nest(image_card, view: :source, size: opts[:size])
  end

  def image_alt
    image_card&.name
  end

  def text_with_image opts={}
    class_up "media-left", "m-2"
    @image_card = Card.cardish(opts[:image]) if opts[:image]
    haml :media_snippet, normalized_text_with_image_opts(opts)
  end

  private

  def normalized_text_with_image_opts opts
    opts.reverse_merge! title: _render_title,
                        text: "",
                        src: image_src(opts),
                        alt: image_alt,
                        size: :original,
                        media_opts: {},
                        media_left_extras: "",
                        media_left: ""
  end
end