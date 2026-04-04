# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Renderer
      module Renderer
        extend ActiveSupport::Concern

        TEXT_ATTRIBUTES = (%i[alt label placeholder title] + %w[alt label placeholder title]).freeze

        def to_s
          return @renderer.call(self) if @renderer.present?
          return @context.public_send(@helper_name, self) if @context.respond_to?(@helper_name)

          options = @options.dup
          sanitize_options(:root, element_type, options)
          renderer_method.call(**options, &method(:content))
        end

        alias to_html to_s

        def content
          traverse do |type, options, content|
            args = extract_arguments(type, options)
            renderer_method(type).call(*args, **options, &content)
          end
        end

        protected

          def extract_arguments(type, options)
            # By default, no arguments are extracted
          end

          def sanitize_node_options(node)
            sanitize_options(node.id.underscore, node.type, node.options)
          end

          def sanitize_options(id, type, options)
            options.extract!(*TEXT_ATTRIBUTES).each do |key, value|
              options[key] = text_for(id, type, key, fallback: value)
            end
          end

          def text_for(value, type, subpart = nil, fallback: nil)
            values = { name: i18n_name, type: type, id: value }
            keys = map_i18n_keys(subpart) { |key| format(key, values).to_sym }
            keys << text_for_fallback(fallback) if fallback.present?
            ::I18n.translate(keys.shift, default: keys)
          end

          def text_for_fallback(value)
            value.to_s.underscore.humanize
          end

          def i18n_name
            @name
          end

          def i18n_keys
            @i18n_keys ||= @context.elements_i18n_keys_for(self)
          end

        private

          def renderer_method(type = nil)
            (@methods ||= {})[type] ||= begin
              type = "_#{type}" if type
              specific, general = [name, element_type].product([type]).map(&:join)
              @context.ui.method(@context.ui.respond_to?(specific) ? specific : general)
            end
          end

          def map_i18n_keys(subpart)
            i18n_keys.flat_map do |key|
              next yield(key) if subpart.nil?

              value = yield("#{key}.#{subpart}")
              next value if subpart.to_s != 'label'

              [value, yield(key)]
            end
          end
      end
    end
  end
end
