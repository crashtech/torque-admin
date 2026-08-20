# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Formatter
    class Formatter
      module Declarations
        def formatter(name, helper = nil, wrap: nil, context: nil, &block)
          block ||= ->(value, *args, **options) { public_send(helper, value, *args, **options) }

          context = Formatter.sanitize_context(context)
          method_name = Formatter.method_name(name)

          if wrap
            wrapper = Formatter.wrapper_name(wrap)
            wrapped_block = ->(value, *args, **options) { public_send(wrapper, instance_exec(value, *args, **options, &block), value) }
          end

          define_method(method_name, &(wrapped_block || block))
          Formatter.contexts[instance_method(method_name).hash] = context if context.any?
          method_name
        end

        def formatters(wrap: nil, context: nil, **pairs)
          pairs.each { |name, helper| formatter(name, helper, wrap:, context:) }
        end
      end

      CONTEXT_KEYS = %i[entry attribute collection].freeze
      EMPTY_CONTEXT = [].freeze

      attr_reader :view_context

      def self.contexts
        @contexts ||= {}
      end

      def self.sanitize_context(context)
        context = Array.wrap(context).map(&:to_sym).freeze
        invalid = context - CONTEXT_KEYS
        raise ArgumentError, <<~MSG.squish if invalid.any?
          Unknown formatter context #{invalid.map(&:inspect).join(', ')}.
          Valid contexts are: #{CONTEXT_KEYS.map(&:inspect).join(', ')}.
        MSG

        context
      end

      def self.method_name(name)
        method_names[name]
      end

      def self.wrapper_name(name)
        wrapper_names[name]
      end

      def self.method_names
        @method_names ||= Hash.new { |hash, name| hash[name] = :"#{Elements.formatter_prefix}#{name}" }
      end

      def self.wrapper_names
        @wrapper_names ||= Hash.new { |hash, name| hash[name] = :"#{Elements.wrapper_prefix}#{name}" }
      end

      def initialize(view_context)
        @view_context = view_context
      end

      def format(value, as = nil, fallback: nil, **options)
        context = options.extract!(*CONTEXT_KEYS)
        return collapse(fallback) if value.nil?

        as = view_context.formatter_for(value) if as.nil?
        context_of(as).each { |key| options[key] = context[key] } if as
        result = as ? public_send(as, value, **options) : value
        result != false && result.blank? ? collapse(fallback) : result
      end

      def context_of(name)
        method = view_context.method(self.class.method_name(name))
        self.class.contexts.fetch(method.unbind.hash, EMPTY_CONTEXT)
      end

      def respond_to_missing?(name, include_private = false)
        view_context.respond_to?(self.class.method_name(name)) || super
      end

      def method_missing(name, ...)
        method_name = self.class.method_name(name)
        return super unless view_context.respond_to?(method_name)

        view_context.public_send(method_name, ...)
      end

      private

        def collapse(fallback)
          Elements.act_as_proc?(fallback) ? view_context.collapse_proc(fallback) : fallback
        end
    end
  end
end
