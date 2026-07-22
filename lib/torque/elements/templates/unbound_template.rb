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

          @extension = @identifier.split('.', 2).last
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

        def bind_path(path, prefix = nil)
          @templates[virtual = File.join(*prefix, path)] ||= Template.new(
            nil,
            File.join(Rails.application.paths['app/views'].first, "#{virtual}.#{@extension}"),
            @handler,

            format: @format,
            variant: @variant,
            virtual_path: virtual,

            locals: [],
            template: self,
          )
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
          controller = view.controller.class.allocate
          context = controller.template_context(view.controller.template_assigns)

          compile!(context)
          buffer = ActionView::OutputBuffer.new
          Context.with(view_context: context) do
            context.instance_variable_set(:@rendering_template, template)
            context.instance_variable_set(:@view_context, controller.view_context)
            context._run(method_name, self, context.assigns, buffer, has_strict_locals: strict_locals?)
          end

          expected_locals.concat(context.request_locals_names.map(&:freeze)).freeze if expected_locals
          save_source!("#{context.required_locals_annotation}\n#{buffer.to_s}", template)
        rescue ActionView::StrictLocalsError => e
          raise StrictLocalsError.new(e, template)
        end

        def save_sources_on
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

          def save_source!(source, template)
            return source if (base = save_sources_on).blank?

            source = HtmlBeautifier.beautify(source) if defined?(HtmlBeautifier)
            FileUtils.mkdir_p(File.join(base, File.dirname(template.virtual_path)))
            File.write(File.join(base, "#{template.virtual_path}.#{@extension}"), source)
            source
          end

          def locals_code
            '@required_locals = {};'
          end
      end
    end
  end
end
