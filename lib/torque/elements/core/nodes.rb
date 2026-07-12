# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Nodes
      module Nodes
        extend ActiveSupport::Concern

        POSITION_OPTIONS = %i[insert_after insert_before prepend_to append_to].freeze

        def children
          @children ||= load_config!.then { @root.children }
        end

        alias nodes children

        def traverse(source = children, **, &block)
          if source.is_a?(Node)
            return block.call(source) if source.leaf?

            source = source.children
          end

          Traverse.new(source, **).each(&block)
        end

        def move(node, **options)
          node = fetch(node) unless node.is_a?(Node)

          options[:insert_after] = options.delete(:after) if options[:after]
          options[:insert_before] = options.delete(:before) if options[:before]

          (node.parent&.children || children).delete(node)
          add_on_position(node, options)
        end

        protected

          def append_node(node, options = node.settings)
            add_on_position(node, options) || add_on_position!(node)
          end

          def shift_node(node)
            (node.parent&.children || children).delete(node)
          end

          def add_on_position(node, options = node.settings)
            return unless options

            POSITION_OPTIONS.find do |position|
              value = options[position]

              next unless [Node, Symbol, TrueClass, FalseClass].include?(value.class)
              next unless (ref = ref_to_node(value))

              add_on_position!(node, ref, position)
            end
          end

        private

          def add_on_position!(node, ref = @current || root, operation = :append_to)
            case operation
            when :prepend_to then (parent = ref).children.unshift(node)
            when :append_to then (parent = ref).children.push(node)
            when :insert_before
              nodes = (parent = ref.parent || root).children
              nodes.insert(nodes.index(ref), node)
            when :insert_after
              nodes = (parent = ref.parent || root).children
              nodes.insert(nodes.index(ref) + 1, node)
            end

            node.instance_variable_set(:@element, self)
            node.instance_variable_set(:@parent, parent)
          end
      end
    end
  end
end
