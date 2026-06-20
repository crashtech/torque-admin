# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Helpers
      module Helpers
        extend ActiveSupport::Concern

        def settings(key = nil, default = nil)
          (hash = @root.settings).nil? ? default : (key.nil? ? hash : hash.fetch(key, default))
        end

        def settings?(key)
          !!@root.settings&.key?(key)
        end

        def change_setting(key, value)
          @root.settings&.[]=(key, value) || @root.instance_variable_set(:@settings, { key => value })
        end

        def element_settings
          %i[max_depth min_depth]
        end

        def apply_sorting!(range = nil, by: nil, &block)
          block = ->(node) { node.text_for(by) } unless by.nil?
          sortable_lists(range).each { |list| list.sort_by!(&block) }
        end

        def fallback_text_for(*)
          # Override this method to better handle missing translations for specific nodes
        end

        protected

          def i18n_name
            @name
          end

          def i18n_keys
            @i18n_keys ||= Context.view_context.elements_i18n_keys_for(self)
          end

          # TODO: Add support for sorting specific branches only
          def sortable_lists(mode)
            return [children] if mode == :root

            queue = [*children]
            result = mode == :children ? [] : [children]

            while queue.any?
              if (current = queue.shift).branch?
                queue += current.children
                result << current.children
              end
            end

            result
          end
      end
    end
  end
end
