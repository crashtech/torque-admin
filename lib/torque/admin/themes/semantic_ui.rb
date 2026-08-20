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
            table: {
              index: { class: 'striped stackable selectable compact' },
            },
            button: {
              primary: { class: 'primary' },
              danger: { class: 'negative' },
            }
          }
        end

        def breadcrumb_with_dividers = true

        def logo(src, **kwargs)
          options = { src: , class: 'logo', style: { display: 'inline-block', margin_right: settings[:default_gap] } }
          render_tag('img', [options, kwargs])
        end

        def application_banner(content, **kwargs)
          menu_item(content, url_for(:root), **kwargs)
        end

        def page_content(as: 'main', **kwargs, &)
          options = { class: 'ui fluid container', style: { 'padding-inline' => settings[:default_gap] } }
          render_content_tag(as, nil, [options, kwargs], &)
        end

        def page_banner(title, description, breadcrumbs, actions, **options)
          description = content_tag('div', description, class: 'sub header') if description.present?
          result = ui.header(safe_join([title, description].compact), style: { 'margin' => '0' })

          if actions.present?
            result = columns('1fr', 'auto', style: { 'align-items' => 'center' }) { safe_join([result, actions]) }
          end

          gap = settings[:default_gap]
          style = { 'margin-top' => "-#{gap}", 'margin-bottom' => '0', 'padding-inline' => gap, 'border-radius' => '0' }

          if breadcrumbs.present?
            rows(2, as: 'header', size: 'min-content', class: 'ui secondary segment', style:) do
              safe_join([breadcrumbs, result])
            end
          else
            content_tag('header', result, class: 'ui secondary segment', style:)
          end
        end

        def page_footer(content)
          content = content_tag('div', content, class: 'ui center aligned container')
          content_tag('footer', content, class: 'ui inverted vertical footer segment')
        end

        ## Extra Elements
        def buttons_button(*, grouped: false, **kwargs)
          grouped ? menu_item(*, **kwargs) : button(*, **kwargs)
        end

        def buttons_group(content, as: :div, **kwargs)
          body = safe_join([kwargs.delete(:label), icon(:dropdown), menu(content)])
          render_content_tag(as, body, [{ class: 'ui dropdown button' }, kwargs])
        end

        def table_skeleton(content = nil, columns:, rows: nil, **kwargs)
          content ||= '<div class="ui placeholder"><div class="line"></div></div>'.html_safe

          columns = columns.call if columns.respond_to?(:call)
          columns = (columns.is_a?(Numeric) ? [nil] * columns : columns).map do |name|
            content_tag('td', content, class: ("col-#{name}" if name))
          end.join

          render_content_tag('tr', columns.html_safe, [kwargs]) * (rows || settings[:default_table_skeleton_rows])
        end
      end
    end
  end
end
