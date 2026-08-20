# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Menu Element
    class MenuElement < BaseElement
      include ItemsFromRouter

      alias import_from_routes import_items_from_router
      alias import_from_sections import_items_from_sections

      # A menu item is a link that may also head a list of additional options. It computes
      # the logical flags at render time (content is built before options are sanitized);
      # the physical composition lives in the ui `menu_entry` helper.
      class ItemNode < Elements::LinkNode
        protected

          def sanitized_options!
            super
            return if content.blank? || options.key?(:dropdown)

            options[:dropdown] = element.settings(:dropdowns, true)
          end
      end

      node :item, as: ItemNode, render: :menu_entry
      node :divider, as: :basic

      setting :sort, :icons, :dropdowns, :detect_current

      ## Define nodes

      def item(identifier, href_or_label = nil, href = nil, **options, &)
        current = self[identifier]
        reindex(current, node_id("#{identifier}-container")) if current && !key?("#{identifier}-container")

        href, href_or_label = href_or_label, nil if href.nil?
        icon = settings(:icons)&.[](identifier)

        options[:href] ||= href
        options[:label] ||= href_or_label || identifier
        options[:icon] ||= icon if icon

        super(identifier, **options, &)
      end

      alias import_item item

      ## Overrides

      def current_link_setting
        settings(:detect_current)
      end

      # TODO: Maybe turn this into a callback
      def load_config!(*)
        return super unless (mode = settings(:sort))

        result = super
        apply_sorting!(mode, by: :label)
        result
      end

      def titlelize_text_for?(key, node)
        node =~ :item && key == :label
      end

      ## Others

      def links
        index.each_value.select { |node| node.is_a?(Elements::LinkNode) }
      end

    end
  end
end
