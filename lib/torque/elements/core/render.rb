# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Render
      module Render
        extend ActiveSupport::Concern

        def render_in(view_context = Context.view_context, &)
          return Context.with(view_context: view_context) { render_in(&) } if view_context != Context.view_context

          @state << 'rendering' << 'rendered'
          block_given? ? load(&) : load_config!
          render_node(root)
        ensure
          @state.delete('rendering')
        end

        alias render render_in
        alias to_s render
        alias to_str render
        alias html_safe render

        def content_of(node, outer: false)
          node = self[node] unless node.is_a?(Node)
          outer ? render_node(node) : render_content(node)
        end

        def render_content(node = @root)
          rendered.fetch(node) { rendered[node] = render_traverse(node) }
        end

        def render_node(node, **)
          invoke_renderer(node, render_content(node), **)
        end

        private

          def render_traverse(node)
            return if node.leaf?

            options = node =~ :root ? settings.slice(:max_depth, :min_depth) : {}
            traverse(node.children, **options).with_content do |node, content|
              invoke_renderer(node, content)
            end
          end

          def invoke_renderer(node, content = nil, **)
            raise ArgumentError, "Node #{node.id} has already been rendered" if @rendered.key?(node.id)

            sanitize_node_options(node)
            args, kwargs = extract_render_options(node)
            @rendered[node.id] = render_method(node).call(*args, content, **kwargs, **, :@node => node)
          end

          def rendered
            @rendered ||= {}
          end

          def render_method(node)
            (@render_method ||= {})[node.type] ||= begin
              source, *args = find_render_method_for(node)
              source&.public_send(*args) || Context.view_context.method(name)
            end
          end

          def find_render_method_for(node, base: Context.view_context)
            name = base.element_helper_name(self, node)
            return [base, :method, name] if base.respond_to?(name)
            return unless base.respond_to?(:ui)

            return [base.ui, :method, :visit] if base.ui.try(:visitors_for?, self, node)

            [base.ui, :method, base.ui.element_helper_name(self, node)]
          end
      end
    end
  end
end
