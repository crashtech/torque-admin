# frozen_string_literal: true

define :button do |b|
  b.preset(:default, as: 'button', class: 'ui button')

  b.property(:multiple).applies(as: 'div', class: { button: false, buttons: true })

  b.property(:label).calls(:label).adds_to_content(:after)
  b.property(:icon).calls(:icon).adds_to_content(:before)

  b.property(:basic).applies(class: 'basic')
  b.property(:tertiary).applies(class: 'tertiary')
  b.property(:inverted).applies(class: 'inverted')
  b.property(:loading).applies(class: 'loading')
  b.property(:disabled).applies(class: 'disabled', disabled: true)
  b.property(:active).applies(class: 'active')
  b.property(:compact).applies(class: 'compact')
  b.property(:toggle).applies(class: 'toggle')
  b.property(:positive).applies(class: 'positive')
  b.property(:negative).applies(class: 'negative')
  b.property(:fluid).applies(class: 'fluid')
  b.property(:circular).applies(class: 'circular')

  b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')
  b.property(:animated).maps(false, true => '').formats(:class, '%s animated')
  b.property(:labeled).maps(false, true => '').formats(:class, '%s labeled')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
  b.property(:social).assigns(:class)
end

def buttons(*args, **kwargs, &block)
  button(*args, multiple: true, **kwargs, &block)
end

define :container do |b|
  b.preset(:default, as: 'div', class: 'ui container')

  b.property(:text).applies(class: 'text')
  b.property(:fluid).applies(class: 'fluid')
  b.property(:resizable).applies(class: 'resizable')

  b.property(:scrolling).maps(false, true => '').formats(:class, '%s scrolling')
  b.property(:alignment).maps(left: 'left aligned', center: 'center aligned', right: 'right aligned', justified: 'justified').assigns(:class)
end

define :divider do |b|
  b.preset(:default, as: 'div', class: 'ui divider')

  b.property(:vertical).applies(class: 'vertical')
  b.property(:horizontal).applies(class: 'horizontal')
  b.property(:inverted).applies(class: 'inverted')
  b.property(:fitted).applies(class: 'fitted')
  b.property(:hidden).applies(class: 'hidden')
  b.property(:section).applies(class: 'section')
  b.property(:clearing).applies(class: 'clearing')

  b.property(:alignment).maps(false, true => '', center: '').formats(:class, '%s aligned')

  b.property(:size).maps_using(:SIZES).assigns(:class)
end

define :emoji, with_content: false do |b|
  b.preset(:default, as: 'em')

  b.argument(:name).assigns(:data_emoji)

  b.property(:disabled).applies(class: 'disabled')
  b.property(:loading).applies(class: 'loading')

  b.property(:size).maps_using(:SIZES).assigns(:class)
end

define :flag, with_content: false do |b|
  b.preset(:default, as: 'i', class: 'ui flag')

  b.argument(:name).assigns(:class)

  b.property(:size).maps_using(:SIZES).assigns(:class)
end

define :header do |b|
  b.preset(:default, as: 'div', class: 'ui header')

  b.property(:icon).calls(:icon).adds_to_content(:before)

  b.property(:sub).applies(class: 'sub')
  b.property(:disabled).applies(class: 'disabled', inert: true)
  b.property(:dividing).applies(class: 'dividing')
  b.property(:block).applies(class: 'block')
  b.property(:inverted).applies(class: 'inverted')

  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:floating).maps(left: 'left floated', right: 'right floated').assigns(:class)
  b.property(:alignment).maps(left: 'left aligned', center: 'center aligned', right: 'right aligned', justified: 'justified').assigns(:class)

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
end

define :icon, with_content: false do |b|
  b.preset(:default, as: 'i')

  b.argument(:name).assigns(:class).formats(:class, using: :ICON)

  b.property(:disabled).applies(class: 'disabled', inert: true)
  b.property(:loading).applies(class: 'loading')
  b.property(:fitted).applies(class: 'fitted')
  b.property(:link).applies(class: 'link')
  b.property(:flipped).applies(class: 'flipped')
  b.property(:rotated).applies(class: 'rotated')
  b.property(:circular).applies(class: 'circular')
  b.property(:colored).applies(class: 'colored')
  b.property(:bordered).applies(class: 'bordered')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
end

define :image do |b|
  b.preset(:default, as: 'img', class: 'ui image')

  b.property(:hidden).applies(class: 'hidden')
  b.property(:disabled).applies(class: 'disabled')
  b.property(:avatar).applies(class: 'avatar')
  b.property(:bordered).applies(class: 'bordered')
  b.property(:fluid).applies(class: 'fluid')
  b.property(:rounded).applies(class: 'rounded')
  b.property(:circular).applies(class: 'circular')
  b.property(:centered).applies(class: 'centered')

  b.property(:valign).maps(false, true => 'middle').formats(:class, '%s aligned')
  b.property(:spaced).maps(false, true => '').formats(:class, '%s spaced')
  b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')

  b.property(:size).maps_using(:SIZES).assigns(:class)
end

define :badge do |b|
  b.preset(:default, as: 'span', class: 'ui label')

  b.property(:multiple).applies(class: { label: false, labels: true })

  b.property(:icon).calls(:icon).adds_to_content(:before)

  b.property(:tag).applies(class: 'tag')
  b.property(:horizontal).applies(class: 'horizontal')
  b.property(:inverted).applies(class: 'inverted')
  b.property(:disabled).applies(class: 'disabled', inert: true)
  b.property(:fluid).applies(class: 'fluid')
  b.property(:centered).applies(class: 'centered')
  b.property(:circular).applies(class: 'circular')
  b.property(:empty).applies(class: 'empty')
  b.property(:basic).applies(class: 'basic')

  b.property(:pointing).maps(true => 'pointing', below: 'pointing below', left: 'left pointing', right: 'right pointing').assigns(:class)
  b.property(:corner).maps(false, true => 'left').formats(:class, '%s ribbon')
  b.property(:ribbon).maps(false, true => '').formats(:class, '%s ribbon')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:floating).maps(false, true => '').formats(:class, '%s floating')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
end

def badges(*args, **kwargs, &block)
  badge(*args, multiple: true, **kwargs, &block)
end

define :loader do |b|
  b.preset(:default, as: 'div', class: 'ui loader')

  b.property(:text).applies(class: 'text')
  b.property(:indeterminate).applies(class: 'indeterminate')
  b.property(:active).applies(class: 'active')
  b.property(:disabled).applies(class: 'disabled')
  b.property(:inverted).applies(class: 'inverted')

  b.property(:inline).maps(false, true => '').formats(:class, '%s inline')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
  b.property(:speed).assigns(:class)
  b.property(:style).assigns(:class)
end

define :placeholder do |b|
  b.preset(:default, as: 'div', class: 'ui placeholder')

  b.property(:fluid).applies(class: 'fluid')
  b.property(:inverted).applies(class: 'inverted')
end

define :rail do |b|
  b.preset(:default, as: 'div', class: 'ui rail')

  b.property(:internal).applies(class: 'internal')
  b.property(:dividing).applies(class: 'dividing')
  b.property(:attached).applies(class: 'attached')

  b.property(:close).maps(false, true => '').formats(:class, '%s close')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:position).assigns(:class)
end

define :reveal do |b|
  b.preset(:default, as: 'div', class: 'ui reveal')

  b.argument(:type).assigns(:class)

  b.property(:instant).applies(class: 'instant')
  b.property(:disabled).applies(class: 'disabled')
  b.property(:active).applies(class: 'active')

  b.property(:move).formats(:class, 'move %s')
  b.property(:rotate).formats(:class, 'rotate %s')
end

define :segment do |b|
  b.preset(:default, as: 'div', class: 'ui segment')

  b.property(:multiple).applies(class: { segment: false, segments: true })

  b.property(:placeholder).applies(class: 'placeholder')
  b.property(:raised).applies(class: 'raised')
  b.property(:stacked).applies(class: 'stacked')
  b.property(:piled).applies(class: 'piled')
  b.property(:vertical).applies(class: 'vertical')
  b.property(:disabled).applies(class: 'disabled', inert: true)
  b.property(:loading).applies(class: 'loading')
  b.property(:inverted).applies(class: 'inverted')
  b.property(:compact).applies(class: 'compact')
  b.property(:circular).applies(class: 'circular')
  b.property(:clearing).applies(class: 'clearing')
  b.property(:basic).applies(class: 'basic')
  b.property(:resizable).applies(class: 'resizable')

  b.property(:horizontal).maps(false, true => '').formats(:class, 'horizontal %s')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:padded).maps(false, true => '').formats(:class, '%s padded')
  b.property(:fitted).maps(false, true => '').formats(:class, '%s fitted')
  b.property(:floated).maps(false, true => 'left').formats(:class, '%s floated')
  b.property(:alignment).maps(false, true => 'left').formats(:class, '%s aligned')
  b.property(:scrolling).maps(false, true => '').formats(:class, '%s scrolling')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
end

def segments(*args, **kwargs, &block)
  segment(*args, multiple: true, **kwargs, &block)
end

define :step do |b|
  b.preset(:default, as: 'div', class: 'ui step')

  b.property(:multiple).applies(class: { step: false, steps: true })

  b.property(:icon).calls(:icon).adds_to_content(:before)

  b.property(:circular).applies(class: 'circular')
  b.property(:ordered).applies(class: 'ordered')
  b.property(:vertical).applies(class: 'vertical')
  b.property(:active).applies(class: 'active')
  b.property(:completed).applies(class: 'completed')
  b.property(:disabled).applies(class: 'disabled', inert: true)
  b.property(:inverted).applies(class: 'inverted')
  b.property(:fluid).applies(class: 'fluid')

  b.property(:alignment).maps(false, true => 'left').formats(:class, '%s aligned')
  b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
  b.property(:stackable).maps(false => 'unstackable', true => 'stackable', tablet: 'tablet stackable').assigns(:class)

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
end

def steps(*args, **kwargs, &block)
  step(*args, multiple: true, **kwargs, &block)
end

define :text do |b|
  b.preset(:default, as: 'span', class: 'ui text')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).assigns(:class)
end
