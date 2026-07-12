# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Menu Element
    class MenuElement < BaseElement
      include ItemsFromRouter

      alias import_from_routes import_items_from_router
      alias import_from_sections import_items_from_sections

      custom_render_for(:item) do |content = nil, **options|
        node = options.delete(:@node)
        label = options.delete(:label)
        as_link = options[:href].present?

        if content.present?
          submenu = ui.submenu(content, **options.delete(:submenu))
          dropdown = !!options[:@element].settings(:dropdowns, true)
          ui.append_options(options, (dropdown ? :append : :after) => submenu)

          label = ui.menu_item(label, options.slice!(:after, :dropdown, :prepend, :append, '@append')) if as_link
          ui.menu_header(label, dropdown: dropdown.presence, **options)
        elsif as_link
          ui.menu_item(label, **options)
        else
          ui.menu_header(label, **options)
        end
      end

      def type = :menu

      def element_settings
        super + %i[sort icons dropdowns detect_current]
      end

      ## Define nodes

      def item(identifier, href_or_label = nil, href = nil, **options, &)
        current = self[identifier]
        reindex(current, node_id("#{identifier}-container")) if current && !key?("#{identifier}-container")

        href, href_or_label = href_or_label, nil if href.nil?
        icon = settings(:icons)&.[](identifier)

        options[:href] ||= href
        options[:label] ||= href_or_label || identifier
        options[:icon] ||= icon if icon

        add_node(identifier, :item, options, node_type: (:link if options[:href]), &)
      end

      alias import_item item

      def divider
        add_node(nil, :divider)
      end

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

      def fallback_text_for(key, value, node)
        value.to_s.underscore.titleize if node =~ :item && key == :label
      end

      ## Others

      def links
        index.each_value.select { |node| node.is_a?(Elements::LinkNode) }
      end

    end
  end
end
