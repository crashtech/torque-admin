# frozen_string_literal: true

require_relative 'helpers/precompile_helper'
require_relative 'helpers/ui_helper'

module Torque
  module Elements
    # = Torque Elements \Helpers
    #
    # This module includes all global helpers for Torque Elements, available both for templates and regular views. It
    # also add the references to known UI frameworks.
    #
    # The naming convention used to bridge across different UI frameworks is the from:
    #  - https://component.gallery/components/
    module Helpers
      extend ActiveSupport::Autoload
      extend ActiveSupport::Concern

      autoload :Template

      autoload :Bootstrap
      autoload :Bulma
      autoload :SemanticUI
      autoload :Tailwind

      include PrecompileHelper
      include UiHelper

      module HookContext
        def in_rendering_context(*)
          Context.initialized? ? super : with_elements_context { super }
        end
      end

      def elements
        Context.elements || Registry.new(self)
      end

      def _run_under(buffer, template)
        _old_output_buffer, _old_virtual_path, _old_template = @output_buffer, @virtual_path, @current_template
        @current_template = template
        @virtual_path = template.virtual_path
        @output_buffer = buffer
        yield self
      ensure
        @output_buffer, @virtual_path, @current_template = _old_output_buffer, _old_virtual_path, _old_template
      end

      private

        def with_elements_context(**extra)
          extra[:view_context] = self
          extra[:elements] = Registry.new(self)

          Context.with(**extra) do
            yield
          ensure
            Context.reset
          end
        end
    end
  end
end
