# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Nodes
      module Nodes
        extend ActiveSupport::Concern

        def clear!
          @children = nil
          super
        end

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
          node = self[node] unless node.is_a?(Core::Node)
          return unless node

          options[:insert_after] = options.delete(:after) if options[:after]
          options[:insert_before] = options.delete(:before) if options[:before]

          (node.parent || self).children.delete(node)
          add_on_position(node, options)
        end

        protected

          def append_node(node)
            add_on_position(node) || (@current || self).children << node
          end

          def shift_node(node)
            (node.parent || self).children.delete(node)
          end

          def add_on_position(node, options = node.options)
            options.extract!(*%i[insert_after insert_before prepend_to append_to]).find do |operation, value|
              next unless [Node, Symbol, TrueClass, FalseClass].include?(value.class)
              next unless (ref = ref_to_node(value))

              break add_on_position!(node, ref, operation)
            end
          end

        private

          def ref_to_node(value)
            return self if value == :root
            return value if value.is_a?(Node)
            return @current || self if value.eql?(true)

            self[value]
          end

          def add_on_position!(node, ref, operation)
            case operation
            when :prepend_to then ref.children.unshift(node)
            when :append_to then ref.children.push(node)
            when :insert_before, :insert_after
              add = operation == :insert_after ? 1 : 0
              parent = ref.parent&.children || nodes
              parent.insert(parent.index(ref) + add, node)
            end
          end
      end
    end
  end
end
