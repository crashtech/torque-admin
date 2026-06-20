# frozen_string_literal: true

module Torque
  module Admin
    module Themes
      module SemanticUI
        include Elements::Helpers::SemanticUI

        def self.elements_presets
          {
            menu: {
              primary_horizontal: { class: 'inverted large', style: { margin: 0, border_radius: 0 } },
              secondary_horizontal: { class: 'large', style: { margin: 0, border_radius: 0 } },
              primary_vertical: { class: 'inverted left vertical', style: { margin: 0, border_radius: 0 } },
            },
            body: {
              default: { style: { min_height: '100vh' } },
              classic: { style: { display: :flex, flex_direction: :column } },
              sidebar: { style: { display: :flex } },
              modern: { style: { display: :flex, flex_direction: :column } },
            },
          }
        end

        def breadcrumb_with_dividers = true

        def body(preset, **kwargs, &content)
          defaults = { class: [preset, app_body_classes] }
          options = build_options(fetch_presets(:default, preset, from: :body), defaults, kwargs)
          render_content_tag(:body, nil, options, &content)
        end

        def application_banner(content, **kwargs)
          menu_item(content, url_for(:root), **kwargs)
        end

        def logo(src, **kwargs)
          options = { src: , class: 'logo', style: { display: 'inline-block', margin_right: '1.5ex' } }
          render_tag(:img, build_options(options, kwargs))
        end
      end
    end
  end
end
