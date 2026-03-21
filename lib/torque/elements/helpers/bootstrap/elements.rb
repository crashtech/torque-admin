# frozen_string_literal: true

define :button do |b|
  b.preset(:default, as: 'button', class: 'btn')

  b.property(:disabled).applies(disabled: true)
  b.property(:active).applies(class: 'active')

  b.property(:outline).formats(:class, 'btn-outline-%s')
  b.property(:color).formats(:class, 'btn-%s')
  b.property(:size).maps(sm: 'btn-sm', lg: 'btn-lg').assigns(:class)

  b.imports(:icon)
end

define :badge do |b|
  b.preset(:default, as: 'span', class: 'badge')

  b.property(:pill).applies(class: 'rounded-pill')
  b.property(:circle).applies(class: 'rounded-circle')

  b.property(:color).formats(:class, 'text-bg-%s')
end

define :alert do |b|
  b.preset(:default, as: 'div', class: 'alert')

  b.toggles(:fade, :show)
  b.property(:dismissible).applies(class: 'alert-dismissible')

  b.property(:color).formats(:class, 'alert-%s')
end

define :card do |b|
  b.preset(:default, as: 'div', class: 'card')

  b.property(:color).formats(:class, 'text-bg-%s')
  b.property(:border).formats(:class, 'border-%s')
end

define :progress do |b|
  b.preset(:default, as: 'div', class: 'progress')
end

define :progress_bar do |b|
  b.preset(:default, as: 'div', class: 'progress-bar')

  b.property(:striped).applies(class: 'progress-bar-striped')
  b.property(:animated).applies(class: 'progress-bar-animated')

  b.property(:color).formats(:class, 'bg-%s')
end

define :spinner do |b|
  b.preset(:default, as: 'div', class: 'spinner-border')

  b.property(:small).applies(class: 'spinner-border-sm')

  b.property(:color).formats(:class, 'text-%s')
end

define :icon do |b|
  b.preset(:default, as: 'i')

  b.argument(:name).assigns(:class).formats(:class, using: :ICON)
end
