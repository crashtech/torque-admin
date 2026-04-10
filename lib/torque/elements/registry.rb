# frozen_string_literal: true

module Torque
  module Elements
    NotFound = Class.new(KeyError)

    # = Torque Elements \Registry
    class Registry < BasicObject
      def initialize(controller)
        @controller = controller
        @instances = {}
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
        # TODO: We should be able to customize the rendering when the block is provided
        # otherwise, rendering the instance should go to +render_in+
        block_given? ? yield(instance) : instance
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
