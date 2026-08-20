# frozen_string_literal: true

require_relative 'helpers/precompile_helper'
require_relative 'helpers/ui_helper'
require_relative 'helpers/formatting'

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

      include PrecompileHelper
      include UiHelper
      include Formatting

      module HookContext
        def in_rendering_context(*)
          Context.initialized? ? super : with_elements_context { super }
        end
      end

      def elements
        Context.registry || Registry.new(controller)
      end

      def template_render_context?
        false
      end

      def collapse_proc(value)
        case value
        when Deferred then value.call(self)
        when Method then value.call
        else instance_exec(&value)
        end
      end

      def render_with_conditions(options)
        removed = FalseClass === options.delete('if')
        removed |= TrueClass === options.delete('unless')
        removed |= TrueClass === options.delete('remove-if')
        removed |= FalseClass === options.delete('remove-unless')

        yield unless removed
      end

      ## Helpers for changing element-based content and options

      def append_changes_to(element, node = :root, **options)
        Context.change(element, node, options)
      end

      def append_content_to(content, element, node = :root, at: 'append')
        return unless content.present?

        raise ArgumentError.new(<<~MSG) unless UiBuilder::CONTENT_OPTIONS.include?(at.to_s)
          Invalid option for `at` argument: #{at.inspect}. Valid options are: #{UiBuilder::CONTENT_OPTIONS.inspect}.
        MSG

        Context.change(element, node, { at.to_sym => content })
      end

      def render_content_to(file, element, node = :root, at: 'append', **)
        raise ArgumentError.new(<<~MSG) unless UiBuilder::CONTENT_OPTIONS.include?(at.to_s)
          Invalid option for `at` argument: #{at.inspect}. Valid options are: #{UiBuilder::CONTENT_OPTIONS.inspect}.
        MSG

        Context.change(element, node, { at.to_sym => { render: file, ** } })
      end

      private

        def with_elements_context(**extra)
          extra[:view_context] = self
          extra[:registry] = Registry.new(controller)

          Context.with(**extra) do
            yield
          ensure
            Context.reset
          end
        end
    end
  end
end
