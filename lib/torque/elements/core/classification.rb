# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Classification
      #
      # The structural grammar of an element: which node types it accepts, what class backs
      # them, whether they are indexed, whether they render at their call site, and which
      # physical parts they can answer. Declarations generate the child DSL methods into a
      # module auto-included in the class, so elements can override them and call +super+.
      module Classification
        extend ActiveSupport::Concern

        Declaration = Struct.new(:type, :klass, :basic, :index, :renders, :parts, :render_name, :one,
          keyword_init: true) do
          def basic? = basic
          def index? = index
          def renders? = renders
          def one? = one
        end

        included do
          class_attribute :node_declarations, instance_writer: false, default: {}.freeze
        end

        class_methods do
          def node(type, as: nil, index: nil, renders: true, one: false, parts: nil, render: nil)
            klass = resolve_node_class(as)
            basic = klass == BasicNode
            raise ArgumentError, +'A basic node is never indexed' if basic && index == true

            declaration = Declaration.new(
              type: type.to_sym,
              klass: klass,
              basic: basic,
              index: !basic && index != false,
              renders: renders,
              parts: parts&.map(&:to_sym)&.freeze,
              render_name: render&.to_sym,
              one: one,
            ).freeze

            self.node_declarations = node_declarations.merge(declaration.type => declaration).freeze
            generate_node_method(declaration)
            declaration
          end

          protected

            def resolve_node_class(as)
              klass =
                case as
                when nil then Node
                when Class then as
                else Node::TYPES.fetch(as.to_sym) { raise ArgumentError, "Unknown node type: #{as.inspect}" }.constantize
                end

              raise ArgumentError, "#{klass} must be a node class" unless klass <= BasicNode

              klass
            end

            def generated_nodes_methods
              @generated_nodes_methods ||= begin
                mod = const_set(:GeneratedNodesMethods, Module.new)
                include(mod)
                mod
              end
            end

          private

            def generate_node_method(declaration)
              if declaration.basic?
                generated_nodes_methods.define_method(declaration.type) do |**options, &block|
                  add_declared_node(declaration, nil, options, &block)
                end
              else
                generated_nodes_methods.define_method(declaration.type) do |identifier, **options, &block|
                  add_declared_node(declaration, identifier, options, &block)
                end
              end
            end
        end

        def declaration_for(type)
          node_declarations[type.to_sym]
        end

        protected

          def add_declared_node(declaration, identifier, options, &block)
            if declaration.one? && nodes_of_type(declaration.type).any?
              raise ArgumentError, "Element '#{name || type}' accepts only one '#{declaration.type}' node"
            end

            if !loading? && rendering?
              capture_declared_node(declaration, identifier, options, &block)
            else
              node = build_declared_node(declaration, identifier, options, &block)
              add_node!(node, index: declaration.index?)
              nest_content(node, &block) if block && !node.is_a?(Base)
              node
            end
          end

        private

          def capture_declared_node(declaration, identifier, options, &block)
            node = build_declared_node(declaration, identifier, options, &block)

            if declaration.renders?
              nest_content(node, &block) if block && !node.is_a?(Base)
            else
              add_node!(node, index: declaration.index?, force: true)
            end

            node
          end

          def build_declared_node(declaration, identifier, options, &block)
            node =
              if declaration.basic?
                declaration.klass.new(declaration.type, **options)
              elsif declaration.klass <= Base
                declaration.klass.new(identifier, **options, &block)
              else
                options[:render] = declaration.render_name if declaration.render_name && !options.key?(:render)
                declaration.klass.new(node_id(identifier), declaration.type, **options)
              end

            node.parent = @current || self
            node.element = self
            node
          end
      end
    end
  end
end
