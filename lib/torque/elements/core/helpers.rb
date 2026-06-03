# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Helpers
      module Helpers
        extend ActiveSupport::Concern

        attr_reader :settings

        def initialize
          @settings = @root.options.extract!(*element_settings)
          super
        end

        def clear!
          @settings = nil
          super
        end

        def element_settings
          %i[max_depth min_depth]
        end

        def apply_sorting!(range = nil, &block)
          sortable_lists(range).each { |list| list.sort_by!(&block) }
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

        protected

          def extract_render_options(node)
            [nil, node.options]
          end

          def text_for(value, type, subpart = nil, fallback: nil)
            return fallback if static_text?(fallback)
            raise ::I18n::MissingTranslationData if i18n_keys.empty?

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
            @i18n_keys ||= Context.view_context.elements_i18n_keys_for(self)
          end

          def text_attributes
            %i[alt label placeholder title]
          end

        private

          def static_text?(value)
            value.is_a?(String) && value.frozen?
          end

          def map_i18n_keys(subpart, primary: 'label')
            i18n_keys.flat_map do |key|
              next yield(key) if subpart.nil?

              value = yield("#{key}.#{subpart}")
              next value if subpart.to_s != primary

              [value, yield(key)]
            end
          end
      end
    end
  end
end
