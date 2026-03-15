# frozen_string_literal: true

require 'action_view/template'

require_relative 'templates/details'
require_relative 'templates/resolver'
require_relative 'templates/template'
require_relative 'templates/unbound_template'

module Torque
  module Elements
    # = Torque Elements \Templates
    module Templates
      extend ActiveSupport::Concern

      included do
        def _protected_ivars
          super + %i[@_action_has_frame @_renders_templates] + _template_ivars
        end
        private :_protected_ivars
      end

      class_methods do
        def _template_ivars
          defined?(@_template_ivars) ? @_template_ivars : [].freeze
        end

        def _template_ivars=(value)
          @_template_ivars = value.freeze
        end

        def _template_prefixes
          defined?(@_template_prefixes) ? @_template_prefixes : [].freeze
        end

        def _template_prefixes=(value)
          @_template_prefixes = value.freeze
        end

        def _view_paths=(set)
          super(ActionView::PathSet.new(set.paths.sort_by { |path| path.is_a?(Resolver) ? 1 : -1 }))
        end

        def _build_template_paths(paths)
          ActionView::PathRegistry.instance_exec do
            @file_system_resolver_mutex.synchronize do
              Array.wrap(paths).map { |path| @file_system_resolvers[path] ||= Resolver.new(path) }
            ensure
              file_system_resolver_hooks.each(&:call)
            end
          end
        end

        def append_template_path(path)
          append_view_path(_build_template_paths(path))
        end

        def prepend_template_path(path)
          prepend_view_path(_build_template_paths(path))
        end
      end

      def template_context_class
        Templates::RenderContext
      end

      def template_context(context = view_context)
        template_context_class.new(lookup_context, template_assigns, self, context)
      end

      def template_assigns
        _template_ivars.each_with_object({}) do |name, hash|
          hash[name[1..-1].to_sym] = instance_variable_get(name) if instance_variable_defined?(name)
        end
      end

      def details_for_lookup
        super.merge(template_prefixes: self.class._template_prefixes)
      end

      private

        def _template_ivars
          self.class._template_ivars.flat_map do |name|
            name.is_a?(Regexp) ? instance_variables.grep(name) : name
          end
        end
    end
  end
end
