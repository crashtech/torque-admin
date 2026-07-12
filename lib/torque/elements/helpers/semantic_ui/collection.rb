define :menu do |b|
  b.preset(:default, as: 'div', class: 'ui menu')
  b.preset(:submenu, class: { ui: false })

  b.toggles(:secondary, :pointing, :tabular, :text, :vertical, :pagination, :inverted, :stackable, :fluid, :compact)
  b.toggles(:borderless, :icon, :wrapping)
  b.property(:labeled_icon).applies(class: 'labeled icon')
  b.property(:disabled).applies(inert: true)

  b.property(:fixed).maps(false, true => 'top').formats(:class, '%s fixed')
  b.property(:attached).maps(false, true => 'top').formats(:class, '%s attached')

  b.imports(:size, :color, :items)
end

associate :submenu, to: :menu, preset: :submenu

define :menu_item do |b|
  b.preset(:default, as: 'a', class: 'item')
  b.preset(:header, as: 'div', class: 'header')

  b.toggles(:active, :link, :fitted)
  b.property(:dropdown).applies(class: ['ui dropdown', { header: false }]).calls(:icon, "('dropdown')").adds_to_content(:append)
  b.property(:disabled).applies(class: 'disabled', inert: true)
  b.property(:label).adds_to_content

  b.imports(:icon, :color)
end

associate :menu_header, to: :menu_item, preset: :header

define :breadcrumb do |b|
  b.preset(:default, as: 'nav', class: 'ui breadcrumb', aria: { label: 'breadcrumb' })

  b.toggles(:inverted)
  b.imports(:size)
end

associate :breadcrumb_item, to: :menu_item

define :table do |b|
  b.preset(:default, as: 'table', class: 'ui table')

  b.toggles(:celled, :structured, :definition, :fixed, :unstackable, :stackable, :selectable, :striped, :basic)
  b.toggles(:collapsing, :inverted, :sortable, :padded, :compact)

  b.property(:very_basic).applies(class: 'very basic')
  b.property(:very_padded).applies(class: 'very padded')
  b.property(:very_compact).applies(class: 'very compact')
  b.property(:single_line).applies(class: 'single line')

  b.property(:aligned).maps(false, true => 'left').formats(:class, '%s aligned')
  b.property(:scrolling).maps(true => '', long: 'long', very_long: 'very long', short: 'short', very_short: 'very short').formats(:class, '%s scrolling')

  b.imports(:size, :color)
end
