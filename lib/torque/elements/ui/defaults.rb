# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Defaults Helpers
    class UiBuilder
      module Defaults
        def node_render_names(node, element = nil)
          return [-element.name.to_s, -element.type.to_s] if element && node =~ :root

          result = []
          result += [-"#{element.name}_#{node.type}", -"#{element.type}_#{node.type}"] if element
          result << -node.type.to_s
          result
        end

        def menu_sections_for(menu)
          [route_annotation(:section)] if menu == :main_menu && current_frame == 'frames/modern'
        end

        ## Layout

        def rows(*values, as: 'div', size: nil, gap: settings[:default_gap], **options, &)
          options = layout_grid_options(:rows, values, size, gap, options)
          render_content_tag(as, nil, options, &)
        end

        def columns(*values, as: 'div', size: nil, gap: settings[:default_gap], **options, &)
          options = layout_grid_options(:columns, values, size, gap, options)
          render_content_tag(as, nil, options, &)
        end

        ## Table

        def table(content = nil, **options, &)
          defaults = { id: options[:@node]&.id, border: 0, cellpadding: 0, cellspacing: 0 }
          render_content_tag('table', content, [defaults, options], &)
        end

        def table_row(content = nil, **options, &)
          render_content_tag('tr', content, [options], &)
        end

        def table_cell(content = nil, **options, &)
          render_content_tag('td', content, [options], &)
        end

        def column_header(content, label: nil, **options)
          id = options[:@node]&.id
          render_content_tag('th', content || label, [{ class: ("col-#{id}" if id) }, options])
        end

        def column_col(*, stretch: false, **options)
          id = options[:@node]&.id
          size = settings[stretch ? :default_col_stretch : :default_col_size]
          render_tag('col', [{ class: ("col-#{id}" if id) }, size, options])
        end

        protected

          def layout_grid_options(direction, values, size, gap, options)
            values = [size || '1fr'] * values.first if values.size == 1 && values.first.is_a?(Integer)
            settings = { 'display' => 'grid', 'gap' => gap, "grid-template-#{direction}" => values.join(' ') }
            build_options({ style: settings }, options)
          end
      end
    end
  end
end
