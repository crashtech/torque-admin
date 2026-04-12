# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Rendering
      module Rendering
        extend ActiveSupport::Concern

        def initialize
          @settings = @root.options.extract!(:helper_method, :max_depth, :min_depth)
          super
        end

        def helper_method
          @settings.fetch(:helper_method) { @controller.element_helper_name(name) }
        end

        def resolve_text_for(node, option)
          node = self[node] unless node.is_a?(Node)

          current = node.options[option]
          return current if static_text?(current)

          node.options[option] = text_for(node.id, node.type, option, fallback: current)
        end

        def sanitize_node_options(node)
          node.options.extract!(*text_attributes).each do |key, value|
            value = text_for(node.id, node.type, key, fallback: value)
            node.options[key] = value unless value.nil?
          end
        end

        def to_s
          render_in(Context.view_context)
        end

        def render_in(context, inline: false, &block)
          raise "Element #{name} has already been rendered" if rendered?

          @state << 'rendering'
          Renderer.render(self, inline: inline, &block)
        ensure
          @state << 'rendered'
        end

        def clear!
          @settings = nil
          super
        end

        protected

          def text_for(value, type, subpart = nil, fallback: nil)
            return fallback if static_text?(fallback)

            values = { name: i18n_name, type: type, id: value }
            keys = map_i18n_keys(subpart) { |key| format(key, values).to_sym }
            ::I18n.translate(keys.shift, default: keys, raise: true).freeze
          rescue ::I18n::MissingTranslationData
            text_for_fallback(fallback, type).freeze if fallback.present?
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

          def text_attributes
            %i[alt label placeholder title]
          end

        private

          def static_text?(value)
            value.is_a?(String) && value.frozen?
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
