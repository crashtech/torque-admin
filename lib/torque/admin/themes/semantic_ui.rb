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
          defaults = { class: [preset, app_body_classes] }
          options = build_options(fetch_presets(:default, preset, from: :body), defaults, kwargs)
          render_content_tag(:body, nil, options, &content)
        end

        def application_banner(content, **kwargs)
          # url_for(:root)
          menu_item(content, '#', **kwargs)
        end

        def logo(src, **kwargs)
          defaults = { src: src, class: 'logo', width: 35, style: { margin_right: '2ex' } }
          render_tag(:img, build_options(defaults, kwargs))
        end

        def app_main_menu(node, content, **kwargs)
          if node =~ :root
            kwargs[:class] = [kwargs[:class], 'left'] if kwargs[:vertical]
            kwargs[:style] = [kwargs[:style], { margin: 0, border_radius: 0 }]
            return menu(content, inverted: true, **kwargs)
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
