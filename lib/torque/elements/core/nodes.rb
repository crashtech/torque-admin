# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Nodes
      module Nodes
        extend ActiveSupport::Concern

        def move(node, **options)
          node = self[node] unless node.is_a?(Core::Node)
          return unless node

          options[:insert_after] = options.delete(:after) if options[:after]
          options[:insert_before] = options.delete(:before) if options[:before]

          (node.parent || self).children.delete(node)
          add_on_position(node, options)
        end

        def traverse(list = nodes, **options, &block)
          Traverse.new(list, **@options.slice(:max_depth, :min_depth), **options).each(&block)
        end

        # TODO: I can turn this into a debug/spec method
        def pretty_inspect(output = ''.dup, ident = 2, list = nodes.dup)
          counter = 0
          output << '   |' << inspect << "\n"
          while (item = list.shift)
            next ident = item if item.is_a?(Integer)

            output << sprintf('%3d|', counter += 1) << (' ' * ident) << item.inspect << "\n"

            unless item.leaf?
              list.unshift(*item.children.dup, ident)
              ident += 2
            end
          end

          output
        end

        protected

          def add_node(node)
            add_on_position(node) || (@current || self).children << node
            super
          end

          def remove_node(node)
            (node.parent || self).children.delete(node)
            super
          end

          def add_on_position(node, options = node.options)
            %i[insert_after insert_before prepend_to append_to].find do |key|
              next unless [Node, Symbol, TrueClass, FalseClass].include?(options[key].class)
              next unless (ref = ref_to_node(options.delete(key)))

              break add_on_position!(node, ref, key)
            end
          end

          def nodes
            @nodes ||= []
          end

          alias children nodes

        private

          def ref_to_node(value)
            return self if value == :root
            return value if value.is_a?(Node)
            return (@current || self) if value.eql?(true)

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
