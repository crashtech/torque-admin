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

      def _run_under(buffer, template)
        _old_output_buffer, _old_virtual_path, _old_template = @output_buffer, @virtual_path, @current_template
        @current_template = template
        @virtual_path = template.virtual_path
        @output_buffer = buffer
        yield self
      ensure
        @output_buffer, @virtual_path, @current_template = _old_output_buffer, _old_virtual_path, _old_template
      end



      def unsafe__menu_item(label, href)
        options = { class: [] }
        options[:class] << 'active' if request.path == href
        link_to(label, href, options)
      end

      def menu_item(label, href)
        return unsafe__menu_item(label, href) if @current_template.virtual_path != 'show'

        "<%= menu_item(#{label.inspect}, #{href.inspect}) %>".html_safe
      end
    end
  end
end
