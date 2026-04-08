# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      module Definition
        extend ActiveSupport::Concern

        attr_reader :name, :options
        alias definition_arg itself

        def initialize(name, controller, definition, *args, **options)
          @name = name
          @controller = controller
          @options = args.grep(Symbol).product([true]).to_h.merge(options)

          super()
          define(&definition)
        end

        def define(&block)
          @current = nil
          @definer = SimpleDelegator.new(self)

          args = block.arity == 1 ? definition_arg : nil
          @definer.instance_exec(*args, &block)
        ensure
          remove_instance_variable(:@current)
          remove_instance_variable(:@definer)
        end

        def element_type
          self.class.name.demodulize.underscore.to_sym
        end

        def include(other)
          other = @controller.elements[other] unless other.is_a?(Base)
          raise ArgumentError, "Expected an element definition, got #{other.class.name}" unless other.is_a?(Base)

          other.traverse do |node, *|
            index_node(node)
            next if node.parent

            (@current&.children || nodes) << node
          end
        end

        def is?(option)
          @options[option.to_sym].eql?(true)
        end

        protected

          def add_node(id, type, skip_depth: false, **options, &block)
            super(node = Node.new(node_id(id), type, options, parent: @current, skip_depth: skip_depth))
            nest_content(node, &block) if block_given?
          end

          def nest_content(node, &block)
            @current = node
            @definer.instance_exec(&block)
          ensure
            @current = node.parent
          end
      end
    end
  end
end
