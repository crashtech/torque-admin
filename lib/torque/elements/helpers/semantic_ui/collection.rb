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
  b.property(:dropdown).applies(class: 'ui dropdown').calls(:icon, "('dropdown')").adds_to_content(:after)
  b.property(:disabled).applies(class: 'disabled', inert: true)
  b.property(:label).adds_to_content

  b.imports(:icon, :color)
end

associate :menu_header, to: :menu_item, preset: :header
