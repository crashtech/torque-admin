# frozen_string_literal: true

module Torque
  module Admin
    module ItemsFromRouter
      def import_items_from_router(route_set = view_context._routes, actions: %w[index show], **settings)
        actions = Array.wrap(actions).map(&:to_s).to_set

        sources = settings.fetch(:sources, %i[resource resources dashboard])
        authenticated_only = settings.fetch(:authenticated_only, true)
        divide_sections = settings.fetch(:divide_sections, false)
        sections_submenu = settings.fetch(:sections_submenu, true)
        add_section_dashboard = settings.fetch(:add_section_dashboard, true)
        filter_sections = settings.fetch(:sections) { import_from_router_sections }.presence

        state = { dashboards: {}, current_section: [], sections: {}, divide_sections:, add_section_dashboard: }

        route_set.routes.each do |route|
          section = route.scope_options.dig(:annotations, :section)&.to_sym
          next if skip_import_route?(route, section, actions, authenticated_only, sources, filter_sections)

          if filter_sections
            state[:current_section] = [section, root]
            section = :root
          else
            section = import_route_section(section, state)
          end

          path = route.defaults
          label, dashboard = route.name.split(/(_?dashboard)$/, 2)

          identifier = label.to_sym
          label = label.delete_prefix("#{state[:current_section].first}_").to_sym

          if dashboard
            import_dashboard_route(route.name.to_sym, label, path, section, state)
          elsif (node = state[:current_section].last)
            import_item(identifier, label, path, append_to: node) if sections_submenu
          else
            import_item(identifier, label, path, append_to: section)
          end
        end
      end

      def import_items_from_sections(list = nil, ignore: nil)
        list ||= view_context.admin_application.instance_variable_get(:@resources).each_value.reduce(Set.new) do |a, r|
          a += r.sections
        end.to_a

        list.each do |section|
          section = section.to_sym
          next if ignore&.include?(section) || ignore&.include?(section.to_s)

          import_item(section, { controller: "#{section}_dashboard", action: :index }, remove_if_invalid: true)
        end
      end

      protected

        def import_from_router_sections
          view_context.app_menu_sections_for(name)
        end

        def skip_import_route?(route, section, actions, authenticated_only, sources, filter_sections)
          (route.verb != 'GET' || route.required_parts.any?) ||
            actions.exclude?(route.defaults[:action]) ||
            (authenticated_only && !route.scope_options.dig(:annotations, :authenticated)) ||
            (sources&.exclude?(route.scope_options.dig(:annotations, :source))) ||
            (filter_sections&.exclude?(section))
        end

        def import_route_section(section, state)
          section = section&.to_sym

          return state[:current_section].clear && :root if section.nil?
          return state[:sections][section] if section == state[:current_section].first

          divider if state[:divide_sections] && state[:sections].any?
          node = state[:sections][section] ||= import_item(section.to_sym)
          state[:current_section] = [section, node]
          node
        end

        def import_dashboard_route(identifier, label, path, section, state)
          if :"#{state[:current_section].first}_dashboard" == identifier
            if state[:add_section_dashboard]
              import_item(identifier, :dashboard, path, prepend_to: state[:current_section].last)
            else
              state[:current_section].last.change(href: path)
            end
          elsif state[:current_section].first.nil? && identifier == :dashboard
            import_item(identifier, :dashboard, path, prepend_to: :root)
          else
            import_item(identifier, label, path, append_to: section)
          end
        end
    end
  end
end
