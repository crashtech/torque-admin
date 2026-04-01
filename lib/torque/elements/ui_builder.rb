# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Helpers
    class UiBuilder
      CONTENT_OPTIONS = (ContentHandler::PARTS - [:content]).map(&:to_s).map(&:freeze).freeze

      attr_reader :view_context

      delegate :attribute_name, to: 'Torque::Elements'
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
          add_framework(name, Elements.ui_framework_helper(name), base: base)
        end

        def add_framework(name, mod, base: UiBuilder)
          raise ::ArgumentError.new(<<~MSG.squish) unless base <= UiBuilder
            #{base} class must be a subclass of UiBuilder.
          MSG

          framework_classes[normalize_name(name)] = Class.new(base).tap { |klass| klass.include(mod) }
        end

        def name_of(instance = self)
          framework_classes.key(instance)
        end

        alias framework_name name_of

        def inspect
          if self.eql?(UiBuilder)
            "#<Torque::Elements::UiBuilder (base class) @frameworks=[#{framework_classes.keys.join(', ')}]>"
          else
            "#<Torque::Elements::UiBuilder (base class) @framework=#{framework_name}>"
          end
        end

        protected

          def normalize_name(name)
            name.to_s.underscore.freeze
          end

        protected

          def framework_classes
            @@framework_classes ||= {}
          end
      end

      def initialize(view_context)
        @view_context = view_context
      end

      def framework_name
        self.class.name_of(self.class) || 'NONE'
      end

      def collapse_options(options)
        options.each_with_object({}) do |(key, value), collapsed|
          collapsed[key] = Elements.find_attribute(key).collapse(value)
        end
      end

      def combine_option(key, current, value)
        current[key] = Elements.find_attribute(key).combine(current[key], value)
      end

      def combine_options(current, options)
        options&.each_with_object(current) { |(key, value), combined| combine_option(key, combined, value) }
      end

      def flatten_options(options, prefix = '')
        return unless options.present?

        options.each_with_object({}) do |(key, value), result|
          attr = attribute_name("#{prefix}#{key}")
          if value.is_a?(Hash) && !Elements.static_attribute?(attr)
            result.merge!(flatten_options(value, "#{prefix}#{key}-"))
          elsif CONTENT_OPTIONS.include?(attr)
            (result['@content'] ||= {})[attr.to_sym] = value
          else
            result[attr] = value
          end
        end
      end

      def inspect
        "#<Torque::Elements::UiBuilder @framework=#{framework_name}>"
      end

      protected

        def tag_builder
          view_context.tag
        end
    end
  end
end
