# frozen_string_literal: true

module Torque
  module Elements
    module Templates
      # = Torque Elements \Unbound Template
      class UnboundTemplate < ActionView::Template
        attr_reader :details

        undef_method :render
        undef_method :instrument_render_template

        def initialize(*, details:, **)
          @details = details
          super(*, details.handler_class, **,
            format: details.format_or_default,
            variant: details.variant&.to_s,
            locals: nil,
          )

          @templates = Concurrent::Map.new(initial_capacity: 2)
        end

        def marshal_dump
          super + [@details]
        end

        def marshal_load(array)
          @details = array.pop
          @templates = Concurrent::Map.new(initial_capacity: 2)
          super(array)
        end

        def bind_path(path)
          @templates[path.virtual] ||= begin
            extension = @identifier.split('.', 2).last

            Template.new(
              nil,
              File.join(Rails.application.paths['app/views'].first, "#{path.virtual}.#{extension}"),
              @handler,

              format: @format,
              variant: @variant,
              virtual_path: path.virtual,

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

        def build_source(view, template, expected_locals = nil)
          controller = view.controller
          context = controller.template_context

          # Temporarily remove the request, because it is not supposed to be accessed during building a template
          # TODO: This is likely to change to a better management way of inaccessible things
          old_request = controller.request
          controller.instance_variable_set(:@_request, nil)

          compile!(context)
          buffer = ActionView::OutputBuffer.new
          controller.view_context._run_under(buffer, self) do |view_context|
            context.instance_variable_set(:@view_context, view_context)
            context._run(method_name, self, context.assigns, buffer, has_strict_locals: strict_locals?)
          end

          expected_locals.concat(context.request_locals_names.map(&:freeze)).freeze if expected_locals
          "#{context.required_locals_annotation}\n#{buffer.to_s}"
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

          def locals_code
            '@required_locals = {};'
          end
      end
    end
  end
end
