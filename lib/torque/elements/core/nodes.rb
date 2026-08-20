# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Nodes
      #
      # Children management and node positioning. The element is its own root: +children+
      # are the element's direct children, and position references resolve against the
      # element itself.
      module Nodes
        extend ActiveSupport::Concern

        def children
          load_config!
          super
        end

        alias_method :nodes, :children

        def traverse(source = children, **, &block)
          if source.is_a?(BasicNode)
            return block.call(source) if source.leaf?

            source = source.children
          end

          Traverse.new(source, **).each(&block)
        end

        def move(node, **options)
          node = fetch(node) unless node.is_a?(BasicNode)

          options[:insert_after] = options.delete(:after) if options[:after]
          options[:insert_before] = options.delete(:before) if options[:before]

          (node.parent&.children || children).delete(node)
          add_on_position(node, options)
        end

        protected

          def append_node(node, options = node.try(:settings))
            add_on_position(node, options) || add_on_position!(node)
          end

          def shift_node(node)
            (node.parent&.children || children).delete(node)
          end

          def add_on_position(node, options = node.try(:settings))
            return unless options

            Node::POSITION_OPTIONS.find do |position|
              value = options[position]

              next unless value.is_a?(BasicNode) || value.is_a?(Symbol) || value.eql?(true) || value.eql?(false)
              next unless (ref = ref_to_node(value))

              add_on_position!(node, ref, position)
            end
          end

        private

          def add_on_position!(node, ref = @current || self, operation = :append_to)
            case operation
            when :prepend_to then (parent = ref).children.unshift(node)
            when :append_to then (parent = ref).children.push(node)
            when :insert_before
              nodes = (parent = ref.parent || self).children
              nodes.insert(nodes.index(ref), node)
            when :insert_after
              nodes = (parent = ref.parent || self).children
              nodes.insert(nodes.index(ref) + 1, node)
            end

            node.parent = parent
            node.element ||= self
            node.instance_variable_set(:@state, @state) if node.is_a?(Base)
            parent
          end
      end
    end
  end
end
