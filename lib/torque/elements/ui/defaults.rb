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

        def rows(*values, as: 'div', size: nil, gap: SETTINGS[:default_gap], **options, &)
          options = layout_grid_options(:rows, values, size, gap, options)
          render_content_tag(as, nil, options, &)
        end

        def columns(*values, as: 'div', size: nil, gap: SETTINGS[:default_gap], **options, &)
          options = layout_grid_options(:columns, values, size, gap, options)
          render_content_tag(as, nil, options, &)
        end

        protected

          def layout_grid_options(direction, values, size, gap, options)
            values = [size || '1fr'] * values.first if values.size == 1 && values.first.is_a?(Integer)
            settings = { 'display' => 'grid', 'gap' => gap, "grid-template-#{direction}" => values.join(' ') }
            build_options(options, { style: settings })
          end
      end
    end
  end
end
