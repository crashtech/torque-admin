# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \SemanticUI Helpers
      module SemanticUI
        extend HelperBuilder

        SIZES = %w[mini tiny small default large big huge massive].each_with_index.with_object({}) do |(name, idx), result|
          result[idx + 1] = result[name] = name == 'default' ? '' : name
        end.with_indifferent_access.freeze

        define_generic do |b|
          b.preset(:default, as: 'div', class: 'ui')

          b.argument(:type).assigns(:class)

          b.property(:disabled).applies(class: 'disabled', inert: true)
          b.property(:size).maps_using(:SIZES).assigns(:class)
          b.property(:color).assigns(:class)
        end

        define :icon, with_content: false do |b|
          b.preset(:default, as: 'i', class: 'icon')

          b.argument(:name).assigns(:class)

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

        define :badge do |b|
          b.preset(:default, as: 'span', class: 'ui label')
          b.preset(:bubble, floating: true)

          b.property(:tag).applies(class: 'tag')
          b.property(:horizontal).applies(class: 'horizontal')
          b.property(:inverted).applies(class: 'inverted')
          b.property(:disabled).applies(class: 'disabled', inert: true)
          b.property(:fluid).applies(class: 'fluid')
          b.property(:centered).applies(class: 'centered')
          b.property(:circular).applies(class: 'circular')
          b.property(:empty).applies(class: 'empty')
          b.property(:basic).applies(class: 'basic')

          b.property(:icon).calls(:icon, '(value)').adds_to_content(:before)
          b.property(:pointing).maps(true => 'pointing', pointing: 'pointing', below: 'pointing below', left: 'left pointing', right: 'right pointing').assigns(:class)
          b.property(:corner).maps(false, true => 'left').formats(:class, '%s ribbon')
          b.property(:ribbon).maps(false, true => '').formats(:class, '%s ribbon')
          b.property(:attached).maps(false, true => '').formats(:class, '%s attached')
          b.property(:floating).maps(false, true => '').formats(:class, '%s floating')

          b.property(:size).maps_using(:SIZES).assigns(:class)
          b.property(:color).assigns(:class)
        end

        alias label badge

      end
    end
  end
end
