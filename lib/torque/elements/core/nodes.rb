# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Nodes
      module Nodes
        extend ActiveSupport::Concern

        def move(key, before: nil, after: nil, prepend_to: nil, append_to: nil)
          return unless (node = self[key])

          remove_node(node)
          if prepend_to && (prepend_to == :root || (ref = self[prepend_to]))
            (ref&.children || nodes).unshift(node)
          elsif append_to && (append_to == :root || (ref = self[append_to]))
            (ref&.children || nodes).push(node)
          else
            add_on_position(node, { before: before, after: after })
          end
        end

        def traverse(list = nodes, max_depth: @max_depth || Float::INFINITY, &block)
          return if list.empty? || max_depth <= 0

          list.map do |node|
            content = -> { traverse(node.children, max_depth: max_depth - 1, &block) } unless node.leaf?

            sanitize_node_options(node)
            block.call(node.type, node.options, content)
          end.then(&@context.method(:safe_join))
        end

        def pretty_inspect(output = ''.dup, ident = 2, list = nodes.reverse)
          output << inspect << "\n"
          while (item = list.pop)
            next ident = item if item.is_a?(Integer)

            output << (' ' * ident) << item.inspect << "\n"

            unless item.leaf?
              list.push(ident, *item.children.reverse)
              ident += 2
            end
          end

          output
        end

        protected

          def node_id(value)
            value.to_s.downcase.gsub(/[_\s]/, '-').gsub(/[^-a-z0-9]/, '')
          end

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
            %i[after before].find do |key|
              next unless options[key].is_a?(Symbol)
              next unless (ref = self[options.delete(key)])

              add = key == :after ? 1 : 0
              source = ref.parent&.children || nodes
              break source.insert(source.index(ref) + add, node)
            end
          end

        private

          def nodes
            @nodes ||= []
          end
      end
    end
  end
end
