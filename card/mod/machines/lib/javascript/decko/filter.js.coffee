decko.slotReady (slot) ->
  slot.find("._filter-widget").each ->
    if slot[0] == $(this).slot()[0]
      filter = new decko.filter this
      filter.showWithStatus "active"

$(window).ready ->
  filterFor = (el) ->
    new decko.filter el

  # Add Filter
  $("body").on "click", "._filter-category-select", (e) ->
    e.preventDefault()
    # e.stopPropagation()
    filterFor(this).activate $(this).data("category")

  # Update filter results based on filter value changes
  onchangers = "._filter-input input:not(.simple-text), " +
    "._filter-input select, ._filter-sort"
  $("body").on "change", onchangers, ->
    return if weirdoSelect2FilterBreaker this
    filterFor(this).update()

  keyupTimeout = null
  $("body").on "keyup", "._filter-input input.simple-text", ->
    clearTimeout keyupTimeout
    filter = filterFor this
    keyupTimeout = setTimeout ( -> filter.update() ), 333

  # remove filter
  $("body").on "click", "._delete-filter-input", ->
    filter = filterFor this
    filter.removeField $(this).closest("._filter-input").data("category")
    filter.update()

  # reset all filters
  $('body').on 'click', '._reset-filter', () ->
    f = filterFor(this)
    f.reset()
    f.update()

  $('body').on 'click', '.filtering .filterable', (e) ->
    f = filterFor($("._filter-widget:visible"))
    if f.widget.length > 0
      data = $(this).data "filter"
      # f.reset()
      f.restrict data["key"], data["value"]
    e.preventDefault()
    # e.stopPropagation()

  $('body').on 'click', '._record-filter', (e) ->
    f = filterFor($("._filter-widget:visible"))
    f.removeField("year")
    data = $(this).data "filter"
    # f.reset()
    f.restrict data["key"], data["value"]

# sometimes this element shows up as changed and breaks the filter.
weirdoSelect2FilterBreaker = (el) ->
  $(el).hasClass "select2-search__field"

# el can be any element inside widget
decko.filter = (el) ->
  @widget = $(el).closest "._filter-widget"
  @activeContainer = @widget.find "._filter-container"
  @dropdown = @widget.find "._add-filter-dropdown"
  @dropdownItems = @widget.find "._filter-category-select"

  @showWithStatus = (status) ->
    f = this
    $.each (@dropdownItems), ->
      item = $(this)
      if item.data status
        f.activate item.data("category")

  @reset = () ->
    @activeContainer.find(".input-group").remove()
    @showWithStatus "default"

  @activate = (category) ->
    @activateField category
    @hideOption category

  @showOption = (category) ->
    @dropdown.show()
    @option(category).show()

  @hideOption = (category) ->
    @option(category).hide()
    @dropdown.hide() if @dropdownItems.length <= @activeFields().length

  @activeFields = () ->
    @activeContainer.find "._filter-input"

  @option = (category) ->
    @dropdownItems.filter("[data-category='#{category}']")

  @findPrototype = (category) ->
    @widget.find "._filter-input-field-prototypes ._filter-input-#{category}"

  @activateField = (category) ->
    field = @findPrototype(category).clone()
    @dropdown.before field
    @initField field
    field.find("input, select").first().focus()

  @removeField = (category)->
    @activeField(category).remove()
    @showOption category

  @initField = (field) ->
    @initSelectField field
    decko.initAutoCardPlete field.find("input")
    # only has effect if there is a data-options-card value

  @initSelectField = (field) ->
    field.find("select").select2(
      containerCssClass: ":all:"
      width: "auto"
      dropdownAutoWidth: "true"
    )

  @activeField = (category) ->
    @activeContainer.find("._filter-input-#{category}")

  @isActive = (category) ->
    @activeField(category).length > 0

  @restrict = (category, value) ->
    @activate category unless @isActive category
    field = @activeField category
    @setInputVal field, value

  # triggers update
  @setInputVal = (field, value) ->
    select = field.find "select"
    if select.length > 0
      @setSelect2Val select, value
    else
      @setTextInputVal field.find("input"), value

  # this triggers change, which updates form
  # if we just use simple "val", the display doesn't update correctly
  @setSelect2Val = (select, value) ->
    value = [value] if select.attr("multiple") && !Array.isArray(value)
    select.select2 "val", value

  @setTextInputVal = (input, value) ->
    input.val value
    @update()

  @update = ()->
    @widget.find("._filter-form").submit()

  this