# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Render
      #
      # The render pass of an element. Rendering state is shared tree-wide: a child element
      # born from a parent adopts the parent's state object, so guards work everywhere while
      # memory stays flat. The +rendered+ state is only set after the pass completes.
      module Render
        extend ActiveSupport::Concern

        def render_content_only!
          @render_content_only = true
        end

        def render_content_only?
          defined?(@render_content_only) && @render_content_only
        end

        def render_in(view_context = Context.view_context, reset: false, &)
          load_config! unless block_given?
          reset_render! if reset && defined?(@rendered)
          with_rendering_context(view_context) do
            load(&) if block_given?
            render!(outer: render_content_only?)
          end
        end

        def render(outer: false)
          return render_in unless rendering?

          load_config!
          super
        end

        def content_of(node, outer: false)
          (node.is_a?(BasicNode) ? node : fetch(node)).render(outer:)
        end

        def render_handler_for(node)
          cache = (@render_methods ||= {})
          key = [node.type, node.render_name]
          cache.fetch(key) { cache[key] = node.resolve_render_handler(self) }
        end

        private

          def with_rendering_context(view_context)
            owner = @state.add?('rendering')

            result =
              if view_context.equal?(Context.view_context)
                yield
              else
                Context.with(view_context:) { yield }
              end

            @state << 'rendered'
            result
          ensure
            @state.delete('rendering') if owner
          end
      end
    end
  end
end
