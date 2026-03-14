# frozen_string_literal: true

module Torque
  module Elements
    module Templates
      # = Torque Elements \Templates Template
      class Template < ActionView::Template
        def initialize(*args, template:, **kwargs)
          @template = template
          super(*args, **kwargs)
        end

        # Hook into render to be able to compile the upper template before rendering the source
        def render(view, locals, **)
          @source ||= @template.build_source(view, self)
          super
        end

        private

          def compiled_source
            old_short_identifier = short_identifier
            @short_identifier = "#{old_short_identifier} (as: #{@template.virtual_path})"
            super
          ensure
            @short_identifier = old_short_identifier
          end

          def instrument_payload
            super.merge(template: @template.identifier)
          end
      end
    end
  end
end
