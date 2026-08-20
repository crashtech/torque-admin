# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \SemanticUI Helpers
      module SemanticUI
        extend HelperConstructor

        ICON = +'icon %s'
        SIZES = %w[mini tiny small default large big huge massive].each_with_index.with_object({}) do |(name, idx), result|
          result[idx + 1] = result[name] = name == 'default' ? '' : name
        end.with_indifferent_access.freeze
        ITEMS = %w[zero one two three four five six seven eight nine ten eleven twelve].each_with_index.to_h.invert

        shared(:icon) { |b| b.calls(:icon).adds_to_content(:prepend) }
        shared(:size) { |b| b.maps_using(:SIZES).assigns(:class) }
        shared(:color) { |b| b.assigns(:class) }
        shared(:items) { |b| b.maps_using(:ITEMS).formats(:class, '%s item') }

        load_definitions './semantic_ui/elements'
        load_definitions './semantic_ui/collection'

        # A menu entry is a plain item when it has no content; with content it becomes a
        # header (linked or not) for a submenu, dropped down or laid side by side
        def menu_entry(content = nil, **options)
          label = options.delete(:label)
          as_link = options[:href].present?

          if content.present?
            submenu = submenu(content, **options.delete(:submenu))
            dropdown = options.delete(:dropdown)
            append_options(options, (dropdown ? :append : :after) => submenu)

            label = menu_item(label, options.slice!(:after, :prepend, :append, '@append')) if as_link
            menu_header(label, dropdown: dropdown.presence, **options)
          elsif as_link
            menu_item(label, **options)
          else
            menu_header(label, **options)
          end
        end

        def pagination(content = nil, **options)
          menu(content, pagination: true, **options)
        end

        def pagination_button(content = nil, grouped: false, active: false, disabled: false, href: nil, **options)
          menu_item(content, active:, disabled:, href: (href unless disabled), **options)
        end

        def pagination_per(*, **)
          pagination_button(*, **)
        end

        def table_column_header(content, sortable: false, direction: nil, href: nil, **options)
          content = link_to(content, href) if sortable && href
          sorted = { class: ['sorted', "#{direction}ending"] } if direction
          render_content_tag('th', content, [sorted, options])
        end
      end
    end
  end
end
