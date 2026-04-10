# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      module Definition
        extend ActiveSupport::Concern

        attr_reader :name, :options

        def initialize(name, controller, definition, *args, **options)
          @name = name
          @controller = controller
          @definition = definition
          @options = args.grep(Symbol).product([true]).to_h.merge(options)

          super()
        end

        def define(&block)
          @current = nil
          @definer = SimpleDelegator.new(self)

          if block.arity == 1
            block.call(@definer)
          else
            @definer.instance_exec(&block)
          end

          self
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

          append_to = @current&.children || nodes
          other.traverse do |node|
            index_node(node)
            append_to << node unless node.parent
          end
        end

        def is?(option)
          @options[option.to_sym].eql?(true)
        end

        protected

          def add_node(id, type, skip_depth: false, **options, &block)
            Node.new(node_id(id), type, @current, skip_depth, **options).tap do |node|
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
