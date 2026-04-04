# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      module Definition
        extend ActiveSupport::Concern

        attr_reader :name, :options
        alias definition_arg itself

        def initialize(name, context, helper_name, definition, **options, &block)
          @name = name
          @context = context
          @helper_name = helper_name
          @renderer = block
          @options = options

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

        protected

          def add_node(id, type, **options, &block)
            super(node = Node.new(node_id(id), type, options, parent: @current))
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
