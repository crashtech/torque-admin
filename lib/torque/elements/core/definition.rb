# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      module Definition
        extend ActiveSupport::Concern

        attr_reader :name, :options, :state, :root

        delegate :id, to: :root
        delegate :initiated?, :configured?, :rendering?, :rendered?, to: :state

        def initialize(name, controller, *args, **options, &config)
          @name = name
          @state = [].inquiry
          @controller = controller
          @config = config

          options = args.grep(Symbol).product([true]).to_h.merge(options)
          @root = Node.new(node_id(name), :root, nil, true, **options)

          super()
          validate!

          @state << 'initiated'
        end

        def change(identifier, **options)
          self[identifier]&.options&.merge!(options)
        end

        def validate!
          # Override in subclasses to perform validation after the definition
        end

        def config!
          return self if configured?

          config(&@config)

          @state << 'configured'
          @config = nil
        end

        def config(&block)
          @current = @root
          @interface = SimpleDelegator.new(self)

          if block.arity == 1
            block.call(@interface)
          else
            @interface.instance_exec(&block)
          end

          self
        ensure
          @current = @interface = nil
        end

        def clear!
          @controller = @root = @state = nil
          super
        end

        def element_type
          self.class.name.demodulize.underscore.to_sym
        end

        def nest_content(node = @root, &block)
          @current = node
          @interface ? @interface.instance_exec(&block) : block.call
          node
        ensure
          @current = node.parent
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
      end
    end
  end
end
