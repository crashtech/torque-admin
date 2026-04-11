# frozen_string_literal: true

module Torque
  module Admin
    module Themes
      module SemanticUI
        include Elements::Helpers::SemanticUI
        # TODO: include Elements::Visitors

        def self.elements_presets
          {
            body: {
              default: { style: { min_height: '100vh' } },
              classic: { style: { display: :flex, flex_direction: :column } },
              sidebar: { style: { display: :flex } },
              modern: { style: { display: :flex, flex_direction: :column } },
            },
          }
        end

        def body(preset, **kwargs, &content)
          options = build_options(fetch_presets(:default, preset, from: :body) << kwargs)
          combine_option('class', options, [preset, app_body_classes])
          render_content_tag(:body, nil, options, &content)
        end

        def application_banner(content, **kwargs)
          menu_header(content, **kwargs)
        end

        def app_main_menu(node, content, **kwargs)
          if node =~ :root
            if kwargs[:vertical]
              kwargs[:class] = [kwargs[:class], 'left']
              kwargs[:style] = [kwargs[:style], { margin: 0, border_radius: 0 }]
            end

            return menu(content, **kwargs)
          end

          menu_link_options(kwargs)
          label = kwargs.delete(:label)
          helper = kwargs[:href].present? ? :menu_item : :menu_header
          return public_send(helper, label, **kwargs) if content.nil?

          kwargs[:after] = [*kwargs[:after], submenu(content, **(kwargs.delete(:submenu) || {}))]
          kwargs[:class] = [kwargs[:class], { header: false }]
          kwargs[:dropdown] = true

          return menu_header(label, **kwargs) if helper == :menu_header

          options = kwargs.extract!(:after, :dropdown, :prepend, :append)
          menu_item(menu_item(label, **kwargs), **options)
        end

        private

          def menu_link_options(options)
            return unless options[:href].present?

            options[:href] = url_for(options[:href])
            options[:class] = [options[:class], { active: view_context.current_page?(options[:href]) }]
          end

      end
    end
  end
end
