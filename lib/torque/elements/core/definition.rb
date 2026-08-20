# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Definition
      #
      # The definition lifecycle of an element: construction, config-block loading, node
      # building, and composition. Loading state (+loading?+/+loaded?+) is per element,
      # while rendering state is shared tree-wide (see Core::Render).
      module Definition
        extend ActiveSupport::Concern

        attr_reader :name, :state

        %i[initiated? rendering? rendered?].each do |state_method|
          define_method(state_method) { @state.include?(state_method.to_s.chomp('?')) }
        end

        def initialize(name = nil, *args, **options, &config)
          raise NotImplementedError, +'Cannot instantiate an abstract class' if self.class.abstract_class?

          @name = name
          @state = Set.new
          @config = config

          super(node_id(name), self.class.element_type, **args.grep(Symbol).product([true]).to_h.merge(options))
          @state << 'initiated'
        end

        def loading?
          defined?(@loading) && @loading
        end

        def loaded?
          defined?(@loaded) && @loaded
        end

        def load_config!(*)
          return self if loading? || loaded?

          # why: loading is tracked per element instead of in @state because @state is shared with nested
          # elements, and a child loading its definition must not read as the parent loading
          begin
            @loading = true
            load(*, &@config) if @config
            @loaded = true
          ensure
            @loading = false
            @config = nil
          end

          self
        end

        def load(*, into: self, &)
          @interface = SimpleDelegator.new(self)
          nest_content(into, *, &)
          self
        ensure
          @interface.__setobj__(nil)
          @current = nil
        end

        def within(node, &)
          nest_content(node.is_a?(BasicNode) ? node : fetch(node), &)
        end

        def change(identifier = self, **options)
          node = identifier.is_a?(BasicNode) ? identifier : fetch(identifier)
          node.equal?(self) ? super(options) : node.change(options)
        end

        def change!(identifier = self, **options)
          node = identifier.is_a?(BasicNode) ? identifier : fetch(identifier)
          node.equal?(self) ? super(options) : node.change!(options)
        end

        def remove(node)
          assert_mutable!

          node = fetch(node) unless node.is_a?(BasicNode)
          unindex_node(node)
          shift_node(node)
        end

        alias delete remove

        def import(other, from: :root, into: :root)
          return import_nodes(other, into) if other.is_a?(Array)
          return import_nodes([other], into) if other.is_a?(BasicNode) && !other.is_a?(Base)

          other = Context.registry[other] unless other.is_a?(Base)
          raise ArgumentError, "Expected an element definition, got #{other.class.name}" unless other.is_a?(Base)

          from = other.fetch(from)
          import_nodes(from.equal?(other) ? from.children : [from], into)
        end

        protected

          def assert_mutable!
            return unless (rendering? || rendered?) && !loading?

            raise +"Cannot change the '#{name || type}' element after it has been rendered"
          end

          def build_node(id, type, options = nil, klass: Node)
            node = klass.new(node_id(id), type, **(options || {}))
            node.parent = @current || self
            node.element = self
            node
          end

          def add_node(id, type, options = nil, klass: Node, &)
            node = build_node(id, type, options, klass:)
            add_node!(node)
            nest_content(node, &) if block_given?
            node
          end

          def nest_content(node = self, *, &block)
            @current = node

            if !loading? && rendering?
              node.content = view_context.capture(@interface, *, &block)
            elsif loading? && block.arity == 0
              @interface.instance_eval(&block)
            else
              yield(@interface || self, *)
            end

            node
          ensure
            @current = node.parent
          end

          def add_node!(node, index: true, force: false)
            assert_mutable! unless force

            append_node(node)
            index_node(node) if index && node.respond_to?(:id) && node.id
            node
          end

          def import_nodes(list, into)
            load_config!

            target = ref_to_node(into)
            list.each do |node|
              copy = deep_copy_node(node)
              copy.parent = target
              target.children << copy
              index_imported_node(copy)
            end
          end

        private

          def deep_copy_node(node, owner = self)
            copy = node.dup
            copy.element = owner
            copy.instance_variable_set(:@state, @state) if copy.is_a?(Base)
            return copy unless node.branch?

            owner = copy if copy.is_a?(Base)
            node.children.each do |child|
              child_copy = deep_copy_node(child, owner)
              child_copy.parent = copy
              copy.children << child_copy
            end

            copy
          end

          def index_imported_node(node)
            index_node(node) if node.respond_to?(:id) && node.id
            return if node.is_a?(Base) || node.leaf?

            node.children.each { |child| index_imported_node(child) }
          end
      end
    end
  end
end
