# frozen_string_literal: true

module Torque
  module Elements
    class BasicNode
      # = Torque Elements \Basic Render Node
      #
      # The rendering portion of BasicNode: content assembly from children and the direct
      # helper dispatch — element method +render_#{type}+, view helper +render_#{name}+,
      # +ui.#{name}+, then the plain content-tag baseline.
      module BasicRender
        def content
          return @content if defined?(@content)
          return unless branch?

          @content = Traverse.new(children, **content_traverse_options).with_content do |node, content|
            node.content = content
            node.render!
          end
        end

        def render!(**)
          raise ArgumentError, "Node '#{type}' has already been rendered" if defined?(@rendered)

          @rendered = nil
          render(**)
        end

        def reset_render!
          remove_instance_variable(:@rendered) if defined?(@rendered)
          remove_instance_variable(:@content) if defined?(@content) && branch?
          children.each(&:reset_render!) if branch?
        end

        def render(outer: false)
          return content if outer

          body = content
          invoke_render(body, sanitized_options)
        end

        alias to_s render
        alias to_str render
        alias html_safe render

        def sanitized_options
          return @options if @options.frozen?

          sanitized_options!
          @options.freeze
        end

        def render_name
          type
        end

        def render_handler
          element ? element.render_handler_for(self) : resolve_render_handler
        end

        def resolve_render_handler(el = element)
          element_method = :"render_#{type}"
          return [:node, el.method(element_method)] if el&.respond_to?(element_method)

          (handler = resolve_dispatch_handler(render_name)) ? [:plain, handler] : [:default, nil]
        end

        def resolve_dispatch_handler(name)
          view = Context.view_context
          helper_method = :"render_#{name}"
          return view.method(helper_method) if view.respond_to?(helper_method)

          ui = view.try(:ui)
          ui.method(name) if ui&.respond_to?(name)
        end

        def dispatch_render(body, **options)
          handler = resolve_dispatch_handler(render_name)
          handler ? handler.call(body, **options) : default_render(body, options)
        end

        protected

          def sanitized_options!
          end

          def content_traverse_options
            {}
          end

          def render_override
          end

          def invoke_render(body, options)
            if (custom = render_override)
              return Context.view_context.instance_exec(body, **options, &custom)
            end

            kind, handler = render_handler
            case kind
            when :node then handler.call(self, body, **options)
            when :plain then handler.call(body, **options)
            else default_render(body, options)
            end
          end

          def default_render(body, options)
            tag_name = options[:as] || type
            Context.view_context.ui.render_content_tag(tag_name, body, [options.except(:as)])
          end
      end
    end
  end
end
