# frozen_string_literal: true

define :button do |b|
  b.preset(:default, as: 'button', class: 'ui button')
  b.preset(:multiple, as: 'div', class: { button: false, buttons: true })

  b.imports(:icon, :size, :color)

  b.property(:label).calls(:label).adds_to_content(:after)

  b.toggles(:basic, :tertiary, :inverted, :loading, :active, :compact, :toggle, :positive, :negative, :fluid, :circular)
  b.property(:disabled).applies(class: 'disabled', disabled: true)

  b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')
  b.property(:animated).maps(false, true => '').formats(:class, '%s animated')
  b.property(:labeled).maps(false, true => '').formats(:class, '%s labeled')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')

  b.property(:social).assigns(:class)
end

associate :buttons, to: :button, preset: :multiple

define :container do |b|
  b.preset(:default, as: 'div', class: 'ui container')

  b.toggles(:text, :fluid, :resizable)

  b.property(:scrolling).maps(false, true => '').formats(:class, '%s scrolling')
  b.property(:alignment).maps(left: 'left aligned', center: 'center aligned', right: 'right aligned', justified: 'justified').assigns(:class)
end

define :divider do |b|
  b.preset(:default, as: 'div', class: 'ui divider')

  b.toggles(:vertical, :horizontal, :inverted, :fitted, :hidden, :section, :clearing)
  b.property(:alignment).maps(false, true => '', center: '').formats(:class, '%s aligned')
  b.imports(:size)
end

define :emoji, with_content: false do |b|
  b.preset(:default, as: 'em')

  b.argument(:name).assigns(:data_emoji)
  b.toggles(:disabled, :loading)
  b.imports(:size)
end

define :flag, with_content: false do |b|
  b.preset(:default, as: 'i', class: 'ui flag')

  b.argument(:name).assigns(:class)
  b.imports(:size)
end

define :header do |b|
  b.preset(:default, as: 'div', class: 'ui header')

  b.imports(:icon, :size, :color)
  b.toggles(:sub, :dividing, :block, :inverted)
  b.property(:disabled).applies(class: 'disabled', inert: true)

  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:floating).maps(left: 'left floated', right: 'right floated').assigns(:class)
  b.property(:alignment).maps(left: 'left aligned', center: 'center aligned', right: 'right aligned', justified: 'justified').assigns(:class)
end

define :icon, with_content: false do |b|
  b.preset(:default, as: 'i')

  b.argument(:name).assigns(:class).formats(:class, using: :ICON)

  b.toggles(:disabled, :loading, :fitted, :link, :flipped, :rotated, :circular, :colored, :bordered)
  b.imports(:size, :color)
end

define :image do |b|
  b.preset(:default, as: 'img', class: 'ui image')

  b.toggles(:hidden, :disabled, :avatar, :bordered, :fluid, :rounded, :circular, :centered)

  b.property(:valign).maps(false, true => 'middle').formats(:class, '%s aligned')
  b.property(:spaced).maps(false, true => '').formats(:class, '%s spaced')
  b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')
  b.imports(:size)
end

define :badge do |b|
  b.preset(:default, as: 'span', class: 'ui label')
  b.preset(:multiple, as: 'div', class: { label: false, labels: true })

  b.toggles(:tag, :horizontal, :inverted, :fluid, :centered, :circular, :empty, :basic)
  b.property(:disabled).applies(class: 'disabled', inert: true)

  b.property(:pointing).maps(true => 'pointing', below: 'pointing below', left: 'left pointing', right: 'right pointing').assigns(:class)
  b.property(:corner).maps(false, true => 'left').formats(:class, '%s ribbon')
  b.property(:ribbon).maps(false, true => '').formats(:class, '%s ribbon')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:floating).maps(false, true => '').formats(:class, '%s floating')

  b.imports(:icon, :size, :color)
end

associate :badges, to: :badge, preset: :multiple

define :loader do |b|
  b.preset(:default, as: 'div', class: 'ui loader')

  b.toggles(:text, :indeterminate, :active, :disabled, :inverted)

  b.property(:inline).maps(false, true => '').formats(:class, '%s inline')
  b.imports(:size, :color)

  b.property(:speed).assigns(:class)
  b.property(:style).assigns(:class)
end

define :placeholder do |b|
  b.preset(:default, as: 'div', class: 'ui placeholder')

  b.toggles(:fluid, :inverted)
end

define :rail do |b|
  b.preset(:default, as: 'div', class: 'ui rail')

  b.toggles(:internal, :dividing, :attached)

  b.property(:close).maps(false, true => '').formats(:class, '%s close')
  b.property(:position).assigns(:class)
  b.imports(:size)
end

define :reveal do |b|
  b.preset(:default, as: 'div', class: 'ui reveal')

  b.argument(:type).assigns(:class)

  b.toggles(:instant, :disabled, :active)

  b.property(:move).formats(:class, 'move %s')
  b.property(:rotate).formats(:class, 'rotate %s')
end

define :segment do |b|
  b.preset(:default, as: 'div', class: 'ui segment')
  b.preset(:multiple, class: { segment: false, segments: true })

  b.toggles(:placeholder, :raised, :stacked, :piled, :vertical, :loading, :inverted, :compact, :circular, :clearing, :basic, :resizable)
  b.property(:disabled).applies(class: 'disabled', inert: true)

  b.property(:horizontal).maps(false, true => '').formats(:class, 'horizontal %s')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:padded).maps(false, true => '').formats(:class, '%s padded')
  b.property(:fitted).maps(false, true => '').formats(:class, '%s fitted')
  b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')
  b.property(:alignment).maps(false, true => 'left').formats(:class, '%s aligned')
  b.property(:scrolling).maps(false, true => '').formats(:class, '%s scrolling')

  b.imports(:size, :color)
end

associate :segments, to: :segment, preset: :multiple

define :step do |b|
  b.preset(:default, as: 'div', class: 'ui step')
  b.preset(:multiple, class: { step: false, steps: true })

  b.toggles(:circular, :ordered, :vertical, :active, :completed, :inverted, :fluid)
  b.property(:disabled).applies(class: 'disabled', inert: true)

  b.property(:alignment).maps(false, true => 'left').formats(:class, '%s aligned')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:stackable).maps(false => 'unstackable', true => 'stackable', tablet: 'tablet stackable').assigns(:class)
  b.imports(:icon, :size, :color)
end

associate :steps, to: :step, preset: :multiple

define :text do |b|
  b.preset(:default, as: 'span', class: 'ui text')
  b.imports(:size, :color)
end
