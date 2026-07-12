# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Context
    class Context < ActiveSupport::CurrentAttributes
      attribute :view_context
      attribute :elements
      attribute :registry
      attribute :refs, default: {}

      delegate :node_id, to: 'Torque::Elements'

      before_reset do
        elements&.clear
        @changes&.clear
      end

      def initialized?
        !view_context.nil?
      end

      def with_ref(name, value)
        old_value = refs[name.to_sym]
        add_ref(name, value)
        yield
      ensure
        add_ref(name, old_value)
      end

      def add_ref(name, value)
        refs[name.to_sym] = value.to_s
      end

      def apply_changes(element, node, current)
        items = @changes&.dig(element, node)
        view_context.ui.append_options(current, items) if items
        current
      end

      def change(element, node = :root, options = nil, **changes)
        element = element.name if element.is_a?(Base)
        return if (options ||= changes).empty? || (id = node_id(node)).nil?

        @changes ||= {}
        @changes[element] ||= {}
        @changes[element][id] ||= []
        @changes[element][id] << options
      end

      def deep_extract_properties(property_list, *inputs)
        while inputs.any?
          next if (input = inputs.pop).blank?

          append = input['@append']
          inputs.push(*append.reverse) if append.present?
          yield(input.extract!(*property_list), input)
        end
      end
    end
  end
end
