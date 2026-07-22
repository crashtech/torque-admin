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

      def group(identifier, label = nil, **options, &)
        add_node(identifier, :group, options.reverse_merge(label: label || identifier), &)
      end

      def item(identifier, href_or_label, href = nil, **options, &)
        href, href_or_label = href_or_label, nil if href.nil?
        icon = settings(:icons)&.[](identifier)

        options[:as] ||= 'a'
        options[:href] ||= href
        options[:icon] ||= icon if icon
        options[:label] ||= href_or_label || identifier unless icons_only?

        add_node(identifier, :button, options, node_type: :link, &)
      end

      alias button item

      def divider
        add_node(nil, :divider)
      end

      ## Renderer

      def titlelize_text_for?(key, node)
        key == :label
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
