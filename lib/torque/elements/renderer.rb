# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Renderer
    class Renderer
      delegate :sanitize_node_options, :element_type, :key?, :has?, to: :@element

      Renderable = Class.new(SimpleDelegator) do
        delegate :html_safe, :to_str, to: :to_s

        def initialize(node, renderer)
          super(node)
          @renderer = renderer
        end

        def to_s
          @renderer.render_node(__getobj__)
        end

        def render_with(**options)
          @renderer.render_node(__getobj__, **options)
        end
      end

      def initialize(element)
        @element = element
        @rendered = {}
      end

      def render(&block)
        unless block_given?
          @element.define!
          return render_node(@element.root)
        end

        @new_nodes = @element.class.new(
          @element.name,
          view_context.controller,
          **@element.options,
        )

        content = view_context.capture { block.call(self) }
        invoke_renderer(@new_nodes.root, content)
      end

      def render_node(node, **options)
        node_content = traverse_for(node) do |node, content|
          invoke_renderer(node, content)
        end

        invoke_renderer(node, node_content, **options)
      end

      ## Accessing and/or defining nodes

      def [](key)
        @element.define!
        node = @element[key]
        Renderable.new(node, self) if node
      end

      def respond_to_missing?(method_name, include_private = false)
        return super if @new_nodes.nil?

        @new_nodes.respond_to?(method_name, include_private) || super
      end

      def method_missing(method_name, *args, **kwargs, &block)
        return super if @new_nodes.nil?

        result = possibly_new_node(method_name, *args, **kwargs, &block)
        result.is_a?(Node) ? Renderable.new(result, self) : result
      end

      private

        def possibly_new_node(method_name, *args, **kwargs, &block)
          return @new_nodes.public_send(method_name, *args, **kwargs) unless block_given?

          content = nil
          capture = view_context.method(:capture)
          outer_block = -> { content = capture.call { block.arity == 1 ? block.call(self) : block.call } }
          result = @new_nodes.public_send(method_name, *args, **kwargs, &outer_block)
          raise ArgumentError, "Expected Node from method call, got #{result.class}" unless result.is_a?(Node)

          invoke_renderer(result, content)
        end

        def traverse_for(node, &block)
          return if node.leaf?

          if node =~ :root
            @element.traverse(node.children).with_content(&block)
          else
            Traverse.new(node.children).with_content(&block)
          end
        end

        def invoke_renderer(node, content = nil, **options)
          raise ArgumentError, "Node #{id} has already been rendered" if @rendered.key?(node.id)

          sanitize_node_options(node)
          @rendered[node.id] = helper_method.call(node, content, **node.options, **options)
        end

        def helper_method
          return @helper_method if defined?(@helper_method)

          source, *args = find_helper_method(name = @element.helper_method)
          @helper_method = source&.public_send(*args) || view_context.method(name)
        end

        def find_helper_method(name)
          return [view_context, :method, name] if view_context.respond_to?(name)
          return unless view_context.respond_to?(:ui)

          return [view_context.ui, :method, name] if view_context.ui.respond_to?(name)
          return unless view_context.ui.respond_to?(:visitors_for)

          [view_context.ui, :visitors_for, @element]
        end

        def view_context
          RenderingContext.view_context
        end
    end
  end
end
