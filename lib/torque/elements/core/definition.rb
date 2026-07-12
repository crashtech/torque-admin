# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      module Definition
        extend ActiveSupport::Concern

        attr_accessor :i18n_options
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
          @root = build_root_node(args, options)

          super()
          @state << 'initiated'
        end

        def load_config!(*)
          return self if loading? || loaded?

          @state << 'loading'
          load(*, &@config) if @config

          @state << 'loaded'
          self
        ensure
          @state.delete('loading')
          @config = nil
        end

        def load(*, into: @root, &)
          @interface = SimpleDelegator.new(self)
          nest_content(into, *, &)
          self
        ensure
          @interface.__setobj__(nil)
          @current = nil
        end

        def type
          raise NotImplementedError, +'Subclasses must implement the #type method'
        end

        def within(node, &)
          nest_content(node.is_a?(Node) ? node : fetch(node), &)
        end

        def change(identifier, **)
          fetch(identifier).change(**)
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

        def import(other, from: :root, into: :root)
          return import_nodes(other, nil, into) if other.is_a?(Array)
          return import_nodes([other], other, into) if other.is_a?(Node)

          other = Context.registry[other] unless other.is_a?(Base)
          raise ArgumentError, "Expected an element definition, got #{other.class.name}" unless other.is_a?(Base)

          from = other.fetch(from)
          import_nodes(from =~ :root ? from.children : [from], from, into)
        end

        protected

          def build_root_node(args, options)
            build_node(@name, :root, args.grep(Symbol).product([true]).to_h.merge(options))
          end

          def build_node(id, type, options = nil, node_type: Node)
            klass = node_type.is_a?(Class) && node_type <= Node ? node_type : Node::CLASS_TYPES[node_type]&.constantize
            raise ArgumentError, "Invalid node type: #{node_type}" if klass.nil?

            klass.new(node_id(id), type, **options, :@element => self)
          end

          def add_node(id, type, options = nil, node_type: nil, &)
            node = build_node(id, type, options, node_type: node_type || Node)
            add_node!(node)
            nest_content(node, &) if block_given?
            node
          end

          def nest_content(node = @root, *, &block)
            @current = node

            if !loading? && rendering?
              node.content = Context.view_context.capture(@interface, *, &block)
            elsif loading? && block.arity == 0
              @interface.instance_eval(&block)
            else
              yield(@interface, *)
            end

            node
          ensure
            @current = node.parent
          end

          def add_node!(node)
            return if rendered?

            append_node(node)
            index_node(node) if node.id
          end

          def import_nodes(list, base, into)
            load_config!

            nodes = ref_to_node(into).children
            # TODO: This doesn't work because we need to copy children and set parents accordingly after dup
            # traverse(list) do |node|
            #   new_node = node.dup
            #   new_node.instance_variable_set(:@element, self)

            #   index_node(node)
            #   nodes << node if node.parent == base
            # end
          end
      end
    end
  end
end
