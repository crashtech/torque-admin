# frozen_string_literal: true

define :block do |b|
  b.preset(:default, as: 'div', class: 'block')
end

define :box do |b|
  b.preset(:default, as: 'div', class: 'box')
end

define :button do |b|
  b.preset(:default, as: 'button', class: 'button')

  b.property(:multiple).applies(as: 'div', class: { button: false, 'has-addons' => true })

  b.property(:icon).calls(:icon).adds_to_content(:before).wrap_content(:span)

  b.property(:light).applies(class: 'is-light')
  b.property(:dark).applies(class: 'is-dark')
  b.property(:responsive).applies(class: 'is-responsive')
  b.property(:fullwidth).applies(class: 'is-fullwidth')
  b.property(:outlined).applies(class: 'is-outlined')
  b.property(:inverted).applies(class: 'is-inverted')
  b.property(:rounded).applies(class: 'is-rounded')
  b.property(:loading).applies(class: 'is-loading')
  b.property(:static).applies(class: 'is-static')
  b.property(:selected).applies(class: 'is-selected')
  b.property(:disabled).applies(disabled: true)

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).formats(:class, 'is-%s')
end

def buttons(*args, **kwargs, &block)
  button(*args, multiple: true, **kwargs, &block)
end

define :content do |b|
  b.preset(:default, as: 'div', class: 'content')

  b.property(:size).maps_using(:SIZES).assigns(:class)
end

define :delete, with_content: false do |b|
  b.preset(:default, as: 'button', class: 'delete')

  b.property(:size).maps_using(:SIZES).assigns(:class)
end

define :icon do |b|
  b.preset(:default, as: 'span', class: 'icon')

  b.argument(:name).calls('@view_context.tag', '(:i, class: format(ICON, value))').adds_to_content

  b.property(:size).maps_using(:SIZES).assigns(:class)
end

define :figure do |b|
  b.preset(:default, as: 'figure', class: 'image')

  b.property(:rounded).applies(class: 'is-rounded')
  b.property(:fullwidth).applies(class: 'is-fullwidth')

  b.property(:size).formats(:class, 'is-%$1sx%$1s')
  b.property(:ratio).maps(false, square: 'square').formats(:class, 'is-%s')
end

define :notification do |b|
  b.preset(:default, as: 'div', class: 'notification')

  b.property(:light).applies(class: 'is-light')
  b.property(:dark).applies(class: 'is-dark')

  b.property(:color).formats(:class, 'is-%s')
end

define :progress, with_content: false do |b|
  b.preset(:default, as: 'progress', class: 'progress')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).formats(:class, 'is-%s')
end

define :badge do |b|
  b.preset(:default, as: 'span', class: 'tag')

  b.property(:multiple).applies(class: { tag: false, tags: true, 'has-addons' => true })

  b.property(:rounded).applies(class: 'is-rounded')
  b.property(:delete).applies(class: 'is-delete')
  b.property(:light).applies(class: 'is-light')
  b.property(:hoverable).applies(class: 'is-hoverable')

  b.property(:size).maps_using(:SIZES).assigns(:class)
  b.property(:color).formats(:class, 'is-%s')
end

alias tag badge

def badges(*args, **kwargs, &block)
  tag(*args, multiple: true, **kwargs, &block)
end

alias tags badges

define :title do |b|
  b.preset(:default, as: 'h1', class: 'title')

  b.property(:spaced).applies(class: 'is-spaced')
  b.property(:subtitle).applies(as: 'h2', class: { title: false, subtitle: true })

  b.property(:size).formats(:class, 'is-%s')
end

def subtitle(*args, **kwargs, &block)
  tag(*args, subtitle: true, **kwargs, &block)
end
