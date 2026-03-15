# frozen_string_literal: true

module Torque
  module Elements
    module Templates
      # = Torque Elements \Templates Template
      class Template < ActionView::Template
        def initialize(*args, template:, **kwargs)
          @template = template
          super(*args, **kwargs)
          @expected_locals = []
        end

        # Hook into render to be able to compile the upper template before rendering the source
        def render(view, locals, *args, **kwargs, &block)
          @source ||= @template.build_source(view, self, @expected_locals)

          locals, block = locals_with_assigns(locals, block, view)
          super(view, locals, *args, **kwargs, &block)
        end

        private
          def compiled_source
            method_name # Pre cache the method name
            old_short_identifier = short_identifier
            @short_identifier = "#{old_short_identifier} (as: #{@template.virtual_path})"
            super
          ensure
            @short_identifier = old_short_identifier
          end

          def locals_with_assigns(locals, block, view)
            assigns = view.controller.view_assigns
            special = @expected_locals.last

            if (key = special[:block]).present?
              value = assigns.delete(key)
              block ||= value
            end

            if (key = special[:kwargs]).present?
              locals = assigns
            elsif locals.empty?
              locals = assigns.slice(*@expected_locals[0..-2])
            end

            [locals.symbolize_keys, block]
          end

          def instrument_payload
            super.merge(template: @template.identifier)
          end
      end
    end
  end
end
