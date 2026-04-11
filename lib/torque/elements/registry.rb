# frozen_string_literal: true

module Torque
  module Elements
    NotFound = Class.new(KeyError)

    # = Torque Elements \Registry
    class Registry < BasicObject
      def initialize(context)
        @context = context
        @controller = context.controller
        @instances = {}
      end

      def new(type, name = nil, **options, &block)
        klass = type.is_a?(::Class) ? as : @controller.element_constructor_for(type)
        valid = klass.is_a?(::Class) && klass <= ::Torque::Elements::Base
        ::Kernel.raise ::ArgumentError, "#{type} is not a valid element reference" unless valid

        instance = klass.new(name, @controller, **options)
        return instance.render_in(@context, &block) if block.present?

        ::Kernel.raise ::ArgumentError, +'Expected a block for inlined element' if name.nil?
        @instances[name] ||= instance
      end

      def fetch(name, *args, **kwargs)
        @instances[name] ||= _find(name).call(@controller, *args, **kwargs)
      end

      alias [] fetch

      def respond_to?(name)
        @instances.key?(name) || _find(name).is_a?(::Proc)
      rescue NotFound
        false
      end

      def respond_to_missing?(name, *)
        respond_to?(name)
      end

      def key?(name)
        respond_to?(name)
      end

      def method_missing(name, *args, **kwargs, &block)
        return respond_to?(name[0..-2]) if name.end_with?('?')

        instance = fetch(name, *args, **kwargs)
        block_given? ? instance.render_in(@controller.view_context, &block) : instance
      end

      def inspect
        "#<#{Registry} for #{@controller.class.name} @instances=#{@instances.keys}>"
      end

      protected

        def _find(name)
          name = name.underscore.to_sym if name.is_a?(::String)

          current = @controller.class
          while current < Controller
            entry = current.elements&.fetch(name, nil)
            return entry if entry

            current = current.superclass
          end

          ::Kernel.raise NotFound, "Element #{name} not found in #{@controller.class}"
        end

    end
  end
end
