# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Defaults Helpers
    class UiBuilder
      module Defaults
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

        ## Pagination

        def pagination(content = nil, **options, &)
          render_content_tag('nav', content, [{ aria: { label: 'pagination' } }, options], &)
        end

        def pagination_button(content = nil, grouped: false, active: false, disabled: false, href: nil, **options)
          tag_name = disabled || href.nil? ? 'span' : 'a'
          state = { href: (href unless disabled), aria: { current: ('page' if active), disabled: (true if disabled) } }
          render_content_tag(tag_name, content, [state, options])
        end

        def pagination_per(*, **)
          pagination_button(*, **)
        end

        ## Table

        def table(content = nil, sortable: false, **options, &)
          render_content_tag('table', content, [{ border: 0, cellpadding: 0, cellspacing: 0 }, options], &)
        end

        def table_colgroup(content = nil, **options, &)
          render_content_tag('colgroup', content, [options], &)
        end

        def table_thead(content = nil, **options, &)
          render_content_tag('thead', content, [options], &)
        end

        def table_tbody(content = nil, **options, &)
          render_content_tag('tbody', content, [options], &)
        end

        def table_tfoot(content = nil, **options, &)
          render_content_tag('tfoot', content, [options], &)
        end

        def table_row(content = nil, **options, &)
          render_content_tag('tr', content, [options], &)
        end

        def table_cell(content = nil, **options, &)
          render_content_tag('td', content, [options], &)
        end

        def table_column_col(stretch: false, width: nil, **options)
          size = width ? { style: { width: } } : settings[stretch ? :default_col_stretch : :default_col_size]
          render_tag('col', [size, options])
        end

        def table_column_header(content, sortable: false, direction: nil, href: nil, **options)
          content = view_context.link_to(content, href) if sortable && href
          aria = { aria: { sort: "#{direction}ending" } } if direction
          render_content_tag('th', content, [aria, options])
        end

        def table_column_cell(content, **options)
          render_content_tag('td', content, [options])
        end

        def table_column_footer(content, **options)
          render_content_tag('td', content, [options])
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
