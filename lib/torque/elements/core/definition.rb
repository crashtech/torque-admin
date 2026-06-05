# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      module Definition
        extend ActiveSupport::Concern

        attr_reader :name, :options, :state, :root

        delegate :id, to: :root

        %i[initiated? loading? loaded? rendering? rendered?].each do |state_method|
          define_method(state_method) { @state.include?(state_method.to_s.chomp('?')) }
        end

        def initialize(name, *args, **options, &config)
          raise NotImplementedError, +'Cannot instantiate an abstract class' if self.class.abstract_class?

          @name = name
          @state = Set.new
          @config = config

          options = args.grep(Symbol).product([true]).to_h.merge(options)
          @root = build_node(name, :root, options)

          super()
          @state << 'initiated'
        end

        def clear!
          @config = @root = @state = nil
          super
        end

        def load_config!
          return self if loading? || loaded?

          @state << 'loading'
          load(&@config) if @config

          @state << 'loaded'
        ensure
          @state.delete('loading')
          @config = nil
        end

        def load(into: @root, &)
          @interface = SimpleDelegator.new(self)
          nest_content(into, &)
          self
        ensure
          @current = @interface = nil
        end

        def type
          raise NotImplementedError, +'Subclasses must implement the #type method'
        end

        def change(identifier, **)
          self[identifier]&.change(**)
        end

        def change!(identifier, **)
          fetch(identifier).change!(**)
        end

        def remove(node)
          raise(+'Cannot remove node after it has been rendered') if rendered?

          node = fetch(node) unless node.is_a?(Node)
          unindex_node(node)
          shift_node(node)
        end

        alias delete remove

        def import(other, from = :root)
          return import_nodes(other, nil) if other.is_a?(Array)
          return import_nodes([other], other) if other.is_a?(Node)

          other = Context.registry[other] unless other.is_a?(Base)
          raise ArgumentError, "Expected an element definition, got #{other.class.name}" unless other.is_a?(Base)

          from = other.fetch(from)
          import_nodes(from =~ :root ? from.children : [from], from)
        end

        protected

          def build_node(id, type, options = {}, skip_depth: false)
            Node.new(node_id(id), type, options, element: self, parent: @current || @root, skip_depth: skip_depth)
          end

          def add_node(id, type, skip_depth: false, **options, &block)
            build_node(id, type, options, skip_depth: skip_depth).tap do |node|
              add_node!(node)
              nest_content(node, &block) if block_given?
            end
          end

          def nest_content(node = @root, &block)
            @current = node

            args = block.arity == 1 ? @interface : nil

            if !loading? && rendering?
              rendered[node] = Context.view_context.capture(*args, &block)
            elsif args
              block.call(args)
            else
              @interface.instance_exec(&block)
            end

            node
          ensure
            @current = node.parent
          end

          def add_node!(node)
            return unless rendered?

            append_node(node)
            index_node(node) if node.id
          end

          def import_nodes(list, base)
            load_config!
            traverse(list) do |node|
              new_node = node.dup
              new_node.instance_variable_set(:@element, self)

              index_node(node)
              append_to << node if node.parent == base
            end
          end
      end
    end
  end
end
