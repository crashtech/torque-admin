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


        def menu(content, **kwargs)
          return super unless kwargs.delete(:@node)

          menu(content, inverted: true, **append_options(kwargs,
            class: { 'left' => kwargs[:vertical] }),
            style: { margin: 0, border_radius: 0 },
          )
        end

        def menu_item(content = nil, link = nil, **kwargs)
          return super unless (node = kwargs.delete(:@node))

          label = kwargs.delete(:label)
          as_link = kwargs[:href].present?

          return (as_link ? super(label, **kwargs) : menu_header(label, **kwargs)) if content.nil?

          submenu = submenu(content, **kwargs.delete(:submenu))
          append_options(kwargs, class: { header: false }, append: submenu)

          return menu_header(label, dropdown: true, **kwargs) unless as_link

          options = kwargs.extract!(:after, :dropdown, :prepend, :append, '@append')
          menu_item(menu_item(label, **kwargs), **options)
        end
      end
    end
  end
end
