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
        class_attribute :_template_ivars, instance_accessor: false, default: [].freeze
        class_attribute :_template_prefixes, instance_accessor: false, default: [].freeze
        private_class_method :_template_ivars=, :_template_prefixes=

        def _protected_ivars
          super + _template_ivars
        end
        private :_protected_ivars
      end

      class_methods do
        def provide_template_ivars(*names)
          self._template_ivars = (_template_ivars + names).uniq
          self._template_ivars.freeze
        end

        def append_template_path(path)
          append_view_path(_build_template_path(path))
        end

        def prepend_template_path(path)
          prepend_view_path(_build_template_path(path))
        end

        protected

          def _view_paths=(set)
            super(ActionView::PathSet.new(set.paths.sort_by { |path| path.is_a?(Resolver) ? 1 : -1 }))
          end

          def _build_template_path(path)
            ActionView::PathRegistry.instance_exec do
              @file_system_resolver_mutex.synchronize do
                @file_system_resolvers[path] ||= Resolver.new(path)
              ensure
                file_system_resolver_hooks.each(&:call)
              end
            end
          end
      end

      def template_context_class
        Templates::RenderContext
      end

      def template_context
        template_context_class.new(lookup_context, template_assigns, self)
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
