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

          remove_node(node)
          add_on_position(node, options)
        end

        def traverse(list = nodes, max_depth: @max_depth || Float::INFINITY, &block)
          return if list.empty? || max_depth <= 0

          list.map do |node|
            if node.branch?
              max_depth = node.skip_depth? ? max_depth : max_depth - 1
              content = traverse(node.children, max_depth: max_depth, &block)
            end

            block.call(node, content)
          end
        end

        def pretty_inspect(output = ''.dup, ident = 2, list = nodes.dup)
          output << inspect << "\n"
          while (item = list.shift)
            next ident = item if item.is_a?(Integer)

            output << (' ' * ident) << item.inspect << "\n"

            unless item.leaf?
              list.unshift(*item.children.dup, ident)
              ident += 2
            end
          end

          output
        end

        protected

          def add_node(node)
            add_on_position(node) || (@current&.children || nodes) << node
            super(node)
          end

          def nodes_of_type(type)
            nodes.select { |node| node.type == type }
          end

          def remove_node(node)
            (node.parent&.children || nodes).delete(node)
          end

          def add_on_position(node, options = node.options)
            %i[after before prepend append prepend_to append_to].find do |key|
              next unless options[key].is_a?(Symbol)
              next unless (ref = ref_to_node(options.delete(key)))

              break add_on_position!(node, ref, key)
            end
          end

        private

          def ref_to_node(value)
            [true, :root].include?(value) ? self : self[value]
          end

          def add_on_position!(node, ref, operation)
            case operation
            when :prepend, :prepend_to then ref.children.unshift(node)
            when :append, :append_to then ref.children.push(node)
            when :before, :after
              add = operation == :after ? 1 : 0
              parent = ref.parent&.children || nodes
              parent.insert(parent.index(ref) + add, node)
            end
          end

          def nodes
            @nodes ||= []
          end
      end
    end
  end
end
