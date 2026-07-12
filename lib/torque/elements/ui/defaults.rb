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
          render_content_tag('table', content, build_options(defaults, options), &)
        end

        def table_content(content, element, parts)
          safe_join([
            content_tag(:colgroup, parts&.get(:columns)),
            content_tag(:thead, content_tag(:tr, parts&.get(:headers))),
            content,
            view_context.process_table_body(element),
            (content_tag(:tfoot, content_tag(:tr, parts&.get(:footers))) if element.with_footer?),
          ])
        end

        def table_body(content = nil, **options)
          content = options.delete(:@content) if content.nil?
          render_content_tag(:tbody, content, build_options(options))
        end

        def table_row(content = nil, **options)
          content = options.delete(:@content) if content.nil?
          render_content_tag(:tr, content, build_options(options))
        end

        def column_header(content = nil, label: nil, **options)
          id = options[:@node]&.id
          render_content_tag('th', content || label, build_options({ class: ("col-#{id}" if id) }, options))
        end

        def column_col(*, stretch: false, **options)
          id = options[:@node]&.id
          size = settings[stretch ? :default_col_stretch : :default_col_size]
          render_content_tag('col', nil, build_options({ class: ("col-#{id}" if id) }, size, options))
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
