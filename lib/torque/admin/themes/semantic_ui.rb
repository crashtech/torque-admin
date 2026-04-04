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
          options = build_options({ class: 'header item' }, kwargs)
          render_content_tag(:div, content, options)
        end



        def menu(**kwargs, &content)
          options = build_options({ class: 'ui menu' }, kwargs)
          render_content_tag(:div, nil, options, &content)
        end

        def menu_item(**kwargs, &content)
          class_name = content.present? ? 'header item' : 'item'
          options = build_options({ class: class_name }, kwargs)

          link = link_to(options.delete('label'), options.delete('href'), options)
          return link if content.nil?

          content_tag(:div, class: 'item') do
            concat link
            concat content_tag(:div, class: 'menu', &content)
          end
        end

        def menu_header(**kwargs, &content)
          options = build_options({ class: 'header' }, kwargs)
          content_tag(:div, class: 'item') do
            concat content_tag(:div, options.delete('label'), options)
            concat content_tag(:div, class: 'menu', &content)
          end
        end

      end
    end
  end
end
