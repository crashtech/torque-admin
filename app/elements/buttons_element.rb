# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Buttons Element
    class ButtonsElement < BaseElement
      node :button, as: :link
      node :group
      node :divider, as: :basic

      setting :sort, :icons, :icons_only

      ## Define nodes

      def group(identifier, label = nil, **options, &)
        super(identifier, **options.reverse_merge(label: label || identifier), &)
      end

      def item(identifier, href_or_label, href = nil, **options, &)
        href, href_or_label = href_or_label, nil if href.nil?
        icon = settings(:icons)&.[](identifier)

        options[:as] ||= 'a'
        options[:href] ||= href
        options[:icon] ||= icon if icon
        options[:label] ||= href_or_label || identifier unless icons_only?

        button(identifier, **options, &)
      end

      ## Renders

      def render_button(node, content, **options)
        node.dispatch_render(content, grouped: !node.parent.equal?(self), **options)
      end

      ## Overrides

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
