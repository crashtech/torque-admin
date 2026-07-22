# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Helpers
      module Helpers
        extend ActiveSupport::Concern

        def settings(key = nil, default = nil)
          key.nil? ? @root.settings : @root.fetch_setting(key, default)
        end

        def settings?(key)
          !!@root.settings&.key?(key)
        end

        def change_setting(key, value)
          if @root.settings
            @root.settings[key] = value
          else
            @root.instance_variable_set(:@settings, { key => value })
          end
        end

        def element_settings
          %i[max_depth min_depth]
        end

        def apply_sorting!(range = nil, by: nil, &block)
          block = ->(node) { node.text_for(by) } unless by.nil?
          sortable_lists(range).each { |list| list.sort_by!(&block) }
        end

        def titlelize_text_for?(*)
          false
        end

        def implicit_attribute_for?(*)
          false
        end

        protected

          def i18n_name
            @name
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
