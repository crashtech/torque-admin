# frozen_string_literal: true

define :block do |b|
  b.preset(:default, as: 'div', class: 'block')
end

define :box do |b|
  b.preset(:default, as: 'div', class: 'box')
end

define :button do |b|
  b.preset(:default, as: 'button', class: 'button')
  b.preset(:multiple, as: 'div', class: { button: false, 'has-addons' => true })

  b.toggles(:light, :dark, :responsive, :fullwidth, :outlined, :inverted, :rounded, :loading, :static, :selected, format: 'is-%s')
  b.property(:disabled).applies(disabled: true)

  b.imports(:icon, :size, :color)
end

associate :buttons, to: :button, preset: :multiple

define :content do |b|
  b.preset(:default, as: 'div', class: 'content')
  b.imports(:size)
end

define :delete, with_content: false do |b|
  b.preset(:default, as: 'button', class: 'delete')
  b.imports(:size)
end

define :icon do |b|
  b.preset(:default, as: 'span', class: 'icon')

  b.argument(:name).calls('tag_builder.i', '(class: format(ICON, value))').adds_to_content
  b.imports(:size)
end

define :figure do |b|
  b.preset(:default, as: 'figure', class: 'image')

  b.toggles(:rounded, :fullwidth, format: 'is-%s')

  b.property(:size).formats(:class, 'is-%1$sx%1$s')
  b.property(:ratio).maps(false, square: 'square').formats(:class, 'is-%s')
end

define :notification do |b|
  b.preset(:default, as: 'div', class: 'notification')

  b.toggles(:light, :dark, format: 'is-%s')
  b.imports(:color)
end

define :progress, with_content: false do |b|
  b.preset(:default, as: 'progress', class: 'progress')
  b.imports(:size, :color)
end

define :badge do |b|
  b.preset(:default, as: 'span', class: 'tag')
  b.preset(:multiple, as: 'div', class: { tag: false, tags: true, 'has-addons' => true })

  b.toggles(:rounded, :delete, :light, :hoverable, format: 'is-%s')
  b.imports(:size, :color)
end

associate :tag, to: :badge
associate :badges, to: :badge, preset: :multiple
associate :tags, to: :badges

define :title do |b|
  b.preset(:default, as: 'h1', class: 'title')
  b.preset(:subtitle, as: 'h2', class: { title: false, subtitle: true })

  b.property(:spaced).applies(class: 'is-spaced')
  b.imports(:size)
end

associate :subtitle, to: :title, preset: :subtitle
