# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Render
      module Render
        extend ActiveSupport::Concern

        included do
          class_attribute :custom_renders, instance_accessor: false, default: {}.freeze
        end

        class_methods do
          def custom_render_for(type, &block)
            self.custom_renders = self.custom_renders.merge(type => block).freeze
          end
        end

        def render_content_only!
          @render_content_only = true
        end

        def render_content_only?
          defined?(@render_content_only) && @render_content_only
        end

        def custom_render_for(type, &block)
          render_methods[type.to_sym] = block
        end

        def render_in(view_context = Context.view_context, &)
          with_rendering_context(view_context) do
            block_given? ? load(&) : load_config!
            root.render!(outer: render_content_only?)
          end
        end

        def content_of(node, outer: false)
          (node.is_a?(Node) ? node : fetch(node)).render(outer:)
        end

        def render_handler_for(node)
          render_methods[render_cache_key_for(node)] ||= begin
            if (custom = self.class.custom_renders[node.type])
              ->(*args) { Context.view_context.instance_exec(*args) }
            else
              render_methods[node.type] || node.class.render_handler_for(node, self)
            end
          end
        end

        private

          def with_rendering_context(view_context, &)
            @state << 'rendering' << 'rendered'

            if view_context != Context.view_context
              yield
            else
              Context.with(view_context:, &)
            end
          ensure
            @state.delete('rendering')
          end

          def render_cache_key_for(node)
            [node.type, node.class, type]
          end

          def render_methods
            @render_methods ||= {}
          end

      end
    end
  end
end
