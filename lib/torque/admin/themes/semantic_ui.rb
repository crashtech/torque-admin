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

        def app_banner(content, **kwargs)
          options = build_options({ class: 'header item' }, kwargs)
          render_content_tag(:div, content, options)
        end
      end
    end
  end
end
