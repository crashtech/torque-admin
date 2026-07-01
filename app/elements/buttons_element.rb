# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Buttons Element
    class ButtonsElement < BaseElement
      def type = :buttons

      def element_settings
        super + %i[sort icons icons_only]
      end

      ## Define nodes

      def group(identifier, label = nil, **, &)
        add_node(identifier, :group, label: label || identifier, **, &)
      end

      def item(identifier, href_or_label, href = nil, **, &)
        href, href_or_label = href_or_label, nil if href.nil?
        icon = settings(:icons)&.[](identifier)

        other = { as: 'a', href: }
        other[:label] = href_or_label || identifier unless icons_only?
        other[:icon] = icon if icon

        add_node(identifier, :button, Elements::LinkNode, **other, **, &)
      end

      alias button item

      def divider
        add_node(nil, :divider)
      end

      ## Renderer

      def fallback_text_for(key, value, node)
        value.to_s.underscore.titleize if key == :label
      end

      ## Others

      def icons_only!
        change_setting(:icons_only, true)
      end

      def icons_only?
        settings(:icons_only, false)
      end
    end
  end
end
