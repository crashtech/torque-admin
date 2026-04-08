# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Renderer
      module Renderer
        extend ActiveSupport::Concern

        TEXT_ATTRIBUTES = (%i[alt label placeholder title] + %w[alt label placeholder title]).freeze

        def initialize
          @helper_name = @options.delete(:helper_method) || @controller.element_helper_name(name)
          @content_only = @options.delete(:content_only) || false
        end

        def content_only?
          @content_only
        end

        def render_in(context, &block)
          return render_with_helper(context) unless block_given?

          result = traverse do |node, content|
            content = context.safe_join(content) if content
            render_node(node.id.underscore, node.type, content, node.options, &block)
          end

          result = context.safe_join(result) if result
          return result if content_only?

          render_node('root', element_type, result, options, &block)
        end

        def render_with_helper(context, helper = @helper_name)
          context.respond_to?(helper) ? context.public_send(helper, self) : context.ui.public_send(helper, self)
        end

        protected

          def extract_arguments(type, options)
            # By default, no arguments are extracted
          end

          def sanitize_options(id, type, options)
            options.extract!(*TEXT_ATTRIBUTES).each do |key, value|
              options[key] = text_for(id, type, key, fallback: value)
            end
          end

          def text_for(value, type, subpart = nil, fallback: nil)
            values = { name: i18n_name, type: type, id: value }
            keys = map_i18n_keys(subpart) { |key| format(key, values).to_sym }
            keys << text_for_fallback(fallback, type) if fallback.present?
            ::I18n.translate(keys.shift, default: keys)
          end

          def text_for_fallback(value, *)
            value.is_a?(String) ? value : value.to_s.underscore.humanize
          end

          def i18n_name
            @name
          end

          def i18n_keys
            @i18n_keys ||= @controller.elements_i18n_keys_for(self)
          end

        private

          def render_node(id, type, content, options, &block)
            options = options.dup
            sanitize_options(id, type, options)
            args = extract_arguments(type, options)
            block.call(type, content, *args, **options)
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
