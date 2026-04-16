# frozen_string_literal: true

module Torque
  module Elements
    NotFound = Class.new(KeyError)

    # = Torque Elements \Registry
    class Registry
      def initialize(context)
        @context = context
        @controller = context.controller
        @instances = {}
      end

      def new(type, name = nil, *, **, &)
        klass = @controller.element_class_for(type)
        instance = klass.new(name, @context, *, **)

        return instance.render_in(@context, &) if block_given?
        raise ::ArgumentError, +'Expected a block for inlined element' if name.nil?

        @instances[name] ||= instance
      end

      def store(name, type, *, **, &)
        klass = @controller.element_class_for(type)
        @instances[name] = klass.new(name, @context, *, **, &)
      end

      def fetch(name, *, **kwargs)
        @instances[name] || begin
          name, type, config = fetch_from_controller(name)
          options = @controller.class.inherited_element_settings(name).merge(kwargs)
          store(name, type, *, **options, &config)
        end
      end

      alias [] fetch

      def respond_to?(name)
        @instances.key?(name) || fetch_from_controller(name)
      rescue NotFound
        false
      end

      def rendered?(name)
        !!@instances[name]&.rendered?
      end

      def respond_to_missing?(name, *)
        respond_to?(name)
      end

      def key?(name)
        respond_to?(name)
      end

      def clear!
        @instances.each_value(&:clear!)
        @instances.clear
      end

      def method_missing(name, *, **, &)
        return respond_to?(name[0..-2]) if name.end_with?('?')

        name, mandatory = name[0..-2], true if name.end_with?('!')
        instance = fetch(name, *, **)

        block_given? ? instance.render_in(@context, &) : instance
      rescue NotFound => e
        raise(e) if mandatory

        Elements.logger.warn("Element #{name} not found in #{@controller.class}")
        nil
      end

      def inspect
        "#<#{Registry} for #{@controller.class.name} @instances=#{@instances.keys}>"
      end

      protected

        def fetch_from_controller(name)
          name = name.underscore.to_sym if name.is_a?(String)

          current = @controller.class
          while current < Controller
            entry = current.elements&.fetch(name, nil)
            return entry if entry

            current = current.superclass
          end

          raise NotFound, "Element #{name} not found in #{@controller.class}"
        end

    end
  end
end
