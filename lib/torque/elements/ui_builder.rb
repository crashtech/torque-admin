# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Helpers
    class UiBuilder
      attr_reader :view_context

      delegate_missing_to :view_context

      class << self
        def new(context)
          return super if self != UiBuilder
          return super if (framework = context.try(:controller).try(:ui_framework)).blank?

          raise MissingFrameworkError.new(<<~MSG.squish) unless klass = framework_classes[normalize_name(framework)]
            No UI framework named '#{framework}'.
            Please make sure it is defined and added to the list of supported frameworks.
          MSG

          klass.new(context)
        end

        def enable_framework(name, base: UiBuilder)
          mod = name.to_s.classify.sub(/Ui/, 'UI')
          add_framework(name, Helpers.const_get(mod), base: base)
        end

        def add_framework(name, mod, base: UiBuilder)
          raise ::ArgumentError.new(<<~MSG.squish) unless base <= UiBuilder
            #{base} class must be a subclass of UiBuilder.
          MSG

          framework_classes[normalize_name(name)] = Class.new(base).tap { |klass| klass.include(mod) }
        end

        protected

          def normalize_name(name)
            name.to_s.underscore.freeze
          end

        protected

          def framework_classes
            @framework_classes ||= {}
          end
      end

      def initialize(view_context)
        @view_context = view_context
      end

      def framework_name
        view_context.try(:controller).try(:ui_framework)&.to_s || 'NONE'
      end
    end
  end
end
