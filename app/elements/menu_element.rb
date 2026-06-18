# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Menu Element
    class MenuElement < BaseElement
      def type
        :menu
      end

      def element_settings
        super + %i[sort icons detect_current]
      end

      ## Define nodes

      def item(identifier, href_or_label = nil, href = nil, **, &)
        current = self[identifier]
        reindex(current, node_id("#{identifier}-container")) if current && !key?("#{identifier}-container")

        href, href_or_label = href_or_label, nil if href.nil?
        add_node(identifier, :item, (Elements::LinkNode if href), label: href_or_label || identifier, href:, **, &)
      end

      def divider
        add_node(nil, :divider)
      end

      def import_from_routes(route_set = view_context._routes, actions: %w[index show], **settings)
        actions = Array.wrap(actions).map(&:to_s).to_set

        sources = settings.fetch(:sources, %i[resource resources dashboard])
        authenticated_only = settings.fetch(:authenticated_only, true)
        divide_sections = settings.fetch(:divide_sections, false)
        sections_submenu = settings.fetch(:sections_submenu, true)
        add_section_dashboard = settings.fetch(:add_section_dashboard, true)

        state = { dashboards: {}, current_section: [], sections: {}, divide_sections:, add_section_dashboard: }

        route_set.routes.each do |route|
          next unless route.verb == 'GET' && route.required_parts.empty?
          next unless actions.include?((path = route.defaults)[:action])
          next if authenticated_only && !route.scope_options.dig(:annotations, :authenticated)
          next if sources&.exclude?(route.scope_options.dig(:annotations, :source))

          section = import_route_section(route.scope_options.dig(:annotations, :section), state)

          identifier = route.name.delete_suffix('_dashboard').to_sym
          if route.name.end_with?('_dashboard') || route.name == 'dashboard'
            import_dashboard_route(identifier, path, section, state)
          elsif (node = state[:current_section].last)
            item(identifier, path, append_to: node) if sections_submenu
          else
            item(identifier, path, append_to: section)
          end
        end
      end

      ## Renderer

      def fallback_text_for(key, value, node)
        value.to_s.underscore.titleize if node =~ :item && key == :label
      end

      ## Overrides

      def current_link_setting
        settings(:detect_current)
      end

      def load_config!(*)
        return super unless (mode = settings(:sort))

        result = super
        apply_sorting!(mode, by: :label)
        result
      end

      ## Others

      def links
        index.each_value.select { |node| node.options[:href] }
      end

      def icons_helper
        return @icons_helper if defined?(@icons_helper)

        @icons_helper = build_settings_handler(:icons, :icon)
      end

      protected

        def import_route_section(section, state)
          section = section&.to_sym

          return state[:current_section].clear && :root if section.nil?
          return state[:sections][section] if section == state[:current_section].first

          divider if state[:divide_sections] && state[:sections].any?
          node = state[:sections][section] ||= item(section.to_sym)
          state[:current_section] = [section, node]
          node
        end

        def import_dashboard_route(identifier, path, section, state)
          if state[:current_section].first == identifier
            if state[:add_section_dashboard]
              item(:dashboard, path, prepend_to: state[:current_section].last)
            else
              state[:current_section].last.change(href: path)
            end
          elsif state[:current_section].first.nil? && identifier == :dashboard
            item(identifier, path, prepend_to: :root)
          else
            item(identifier, path, append_to: section)
          end
        end

    end
  end
end
