# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Menu Element
    class MenuElement < BaseElement
      def clear!
        @icons_helper = @detect_current_helper = nil
        super
      end

      def type
        :menu
      end

      def element_settings
        super + %i[sort icons detect_current icon_position]
      end

      ## Define nodes

      def item(identifier, href_or_label = nil, href = nil, **, &)
        current = self[identifier]
        reindex(current, node_id("#{identifier}-container")) if current && !key?("#{identifier}-container")

        href, href_or_label = href_or_label, nil if href.nil?
        add_node(identifier, :item, label: href_or_label || identifier, href: href, **, &)
      end

      def divider
        @dividers ||= 0
        add_node(node_id("-divider-#{@dividers += 1}"), :divider)
      end

      def import_from_routes(route_set = view_context._routes, actions: %w[index show], **settings)
        actions = Array.wrap(actions).map(&:to_s).to_set

        authenticated_only = settings.fetch(:authenticated_only, true)
        divide_sections = settings.fetch(:divide_sections, false)
        sections_submenu = settings.fetch(:sections_submenu, true)
        add_section_dashboard = settings.fetch(:add_section_dashboard, true)

        state = { dashboards: {}, current_section: [], sections: {}, divide_sections:, add_section_dashboard: }

        route_set.routes.each do |route|
          next unless actions.include?((path = route.defaults)[:action])
          next unless route.verb == 'GET' && route.required_parts.empty?
          next if authenticated_only && !route.scope_options.dig(:annotations, :authenticated)

          section = import_route_section(route.scope_options.dig(:annotations, :section), state)

          identifier = route.name
          if identifier.end_with?('_dashboard') || identifier == 'dashboard'
            import_dashboard_route(identifier.delete_suffix('_dashboard').to_sym, path, section, state)
          elsif (node = state[:current_section].last)
            item(identifier.to_sym, path, append_to: node) if sections_submenu
          else
            item(identifier.to_sym, path, append_to: section)
          end
        end
      end

      ## Renderer

      def sanitize_node_options(node)
        return super unless node =~ :item

        node[:href] = view_context.url_for(node[:href]) if node[:href]
        change_current_indicator(node) if settings[:detect_current]
        icons_helper.call(node) if settings[:icons]
        super
      end

      def text_for_fallback(value, *)
        value.is_a?(String) ? value : value.to_s.underscore.titleize
      end

      ## Overrides

      def load_config!(*)
        settings[:sort] ? super.tap { apply_sorting! } : super
      end

      ## Others

      def links
        index.each_value.select { |node| node.options[:href] }
      end

      def apply_sorting!(mode = settings[:sort])
        super(mode) { |node| label_for(node) }
      end

      def label_for(node)
        resolve_text_for(node, :label)
      end

      def change_current_indicator(node)
        node[:active] = true if current_active?(node)
      end

      def current_active?(node)
        node[:href].present? && detect_current_helper.call(node[:href])
      end

      def detect_current_helper
        @detect_current_helper ||= begin
          method = TrueClass === settings[:detect_current] ? :current_page? : settings[:detect_current]
          method.respond_to?(:call) ? method : view_context.method(method)
        end
      end

      def icons_helper
        @icons_helper ||=
          if settings[:icons].is_a?(Hash)
            index = settings[:icons].transform_keys { |key| node_id(key) }
            ->(node) { node[:icon] = index[node.id] }
          else
            helper = TrueClass === settings[:icons] ? :icon : settings[:icons]
            helper = view_context.respond_to?(helper) ? view_context.method(helper) : view_context.ui.method(helper)
            position = settings.fetch(:icon_position, :after)
            ->(node) { node.append(position => helper.call(node.id)) }
          end
      end

      protected

        # TODO: Make this generic to sort by depth number filtered by types
        def sortable_lists(mode)
          return [nodes] if mode == :root

          queue = [*nodes]
          result = mode == :children ? [] : [nodes]

          while queue.any?
            if (current = queue.shift).branch?
              queue += current.children
              result << current.children
            end
          end

          result
        end

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
