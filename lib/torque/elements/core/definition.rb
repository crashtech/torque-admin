# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      module Definition
        extend ActiveSupport::Concern

        attr_reader :name, :options, :root

        def initialize(name, controller, *args, **options, &definition)
          @name = name
          @controller = controller
          @definition = definition

          options = args.grep(Symbol).product([true]).to_h.merge(options)
          @root = Node.new(node_id(name), :root, nil, true, **options)

          super()
        end

        def define(&block)
          @current = @root
          @definer = SimpleDelegator.new(self)

          if block.arity == 1
            block.call(@definer)
          else
            @definer.instance_exec(&block)
          end

          self
        ensure
          @current = @definer = nil
        end

        def define!
          return unless @definition

          define(&@definition)
          @definition = nil
        end

        def element_type
          self.class.name.demodulize.underscore.to_sym
        end

        def include(other)
          other = @controller.elements[other] unless other.is_a?(Base)
          raise ArgumentError, "Expected an element definition, got #{other.class.name}" unless other.is_a?(Base)

          append_to = @current&.children || nodes
          other.traverse do |node|
            index_node(node)
            append_to << node unless node.parent
          end
        end

        protected

          def add_node(id, type, skip_depth: false, **options, &block)
            Node.new(node_id(id), type, @current || @root, skip_depth, **options).tap do |node|
              super(node)
              nest_content(node, &block) if block_given?
            end
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
