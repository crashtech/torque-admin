# frozen_string_literal: true

module Torque
  module Elements
    module Templates
      # = Torque Elements \Unbound Template
      class UnboundTemplate < ActionView::Template
        MatchAllString = Class.new(String) { def ==(*); true; end }
        private_constant :MatchAllString

        attr_reader :details

        undef_method :render
        undef_method :instrument_render_template

        def initialize(*args, details:, virtual_path: nil, **kwargs)
          @details = details
          super(*args, details.handler_class, **kwargs,
            format: details.format_or_default,
            variant: details.variant&.to_s,
            locals: nil,
          )

          @virtual_path = MatchAllString.new(virtual_path.to_s)
          @templates = Concurrent::Map.new(initial_capacity: 2)
        end

        def marshal_dump
          super + [@details]
        end

        def marshal_load(array)
          @details = array.pop
          @templates = Concurrent::Map.new(initial_capacity: 2)
          super(array)
          @virtual_path = MatchAllString.new(@virtual_path)
        end

        def bind_prefix(prefix)
          @templates[prefix] ||= begin
            virtual = File.join(prefix, File.basename(@virtual_path))
            extension = @identifier.split('.', 2).last

            Template.new(
              nil,
              File.join(Rails.application.paths['app/views'].first, "#{virtual}.#{extension}"),
              @handler,

              format: @format,
              variant: @variant,
              virtual_path: virtual,

              locals: [],
              template: self,
            )
          end
        end

        def built_templates
          @templates.values
        end

        def strict_locals!
          super.then { @strict_locals ||= '**nil' }
        end

        def supports_streaming?
          false
        end

        def inspect
          "#<#{self.class.name} #{short_identifier} entries=#{@templates.size}>"
        end

        def build_source(view, template)
          controller = view.controller
          context = controller.template_context

          # Temporarily remove the request, because it is not supposed to be accessed during building a template
          old_request = controller.request
          controller.instance_variable_set(:@_request, nil)

          compile!(context)
          buffer = ActionView::OutputBuffer.new
          context._run(method_name, self, context.assigns, buffer, has_strict_locals: strict_locals?)

          # TODO: Implement intelligent locals annotation, we can detect instance variable accesses and use them as
          # the actual locals of the actual template
          "<%# locals: () %>\n#{buffer.to_s}"
        rescue ActionView::StrictLocalsError => e
          raise StrictLocalsError.new(e, template)
        ensure
          controller.instance_variable_set(:@_request, old_request)
        end

        private
          def compile!(view)
            return if @compiled

            @compile_mutex.synchronize do
              return if @compiled

              old_annotate = ActionView::Base.annotate_rendered_view_with_filenames
              ActionView::Base.annotate_rendered_view_with_filenames = false

              mod = view.compiled_method_container
              instrument('precompile_template') { compile(mod) }

              @compiled = true
            ensure
              ActionView::Base.annotate_rendered_view_with_filenames = old_annotate
            end
          end
      end
    end
  end
end
