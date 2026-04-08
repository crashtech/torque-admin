# frozen_string_literal: true

module Torque
  module Admin
    module Themes
      module SemanticUI
        include Elements::Helpers::SemanticUI

        def self.presets
          Elements::Helpers::SemanticUI.presets.deep_merge(
            body: {
              default: { style: { min_height: '100vh' } },
              classic: { style: { display: :flex, flex_direction: :column } },
              sidebar: { style: { display: :flex } },
              modern: { style: { display: :flex, flex_direction: :column } },
            },
          )
        end

        def body(preset, **kwargs, &content)
          options = build_options(fetch_presets(:default, preset, from: :body) << kwargs)
          combine_option('class', options, [preset, *app_body_classes])
          render_content_tag(:body, nil, options, &content)
        end

        def application_banner(content, **kwargs)
          menu_header(content, **kwargs)
        end

        def application_main_menu(*args, **kwargs)
          element = elements.fetch(:main_menu, *args, **kwargs)
          element.render_in(self) do |node_type, content, *, **kwargs|
            next submenu(content, **kwargs) if node_type == :submenu

            if node_type == :menu
              if element.is?(:vertical)
                kwargs[:class] = [kwargs[:class], 'left']
                kwargs[:style] = [kwargs[:style], { margin: 0, border_radius: 0 }]
              end

              next menu(content, **kwargs)
            end

            label = kwargs.delete(:label)
            menu_link_options(kwargs) if kwargs[:href].present?
            next public_send("menu_#{node_type}", label, **kwargs) if content.blank?

            kwargs[:after] = [*kwargs[:after], content]
            kwargs[:class] = [kwargs[:class], { header: false }]
            kwargs[:dropdown] = true

            next menu_header(label, **kwargs) if node_type == :header

            options = kwargs.extract!(:after, :dropdown, :prepend, :append)
            menu_item(menu_item(label, **kwargs), **options)
          end
        end

        private

          def menu_link_options(options)
            options[:href] = url_for(options[:href]) if options[:href].present?
            options[:class] = [options[:class], { active: view_context.current_page?(options[:href]) }]
          end

      end
    end
  end
end
