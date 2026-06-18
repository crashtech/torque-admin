# frozen_string_literal: true

module Torque
  module Elements
    NotFound = Class.new(KeyError)

    # = Torque Elements \Registry
    class Registry
      def initialize(controller)
        @controller = controller
      end

      def new(type, name = nil, *, **, &)
        klass = @controller.element_class_for(type)
        instance = klass.new(name, *, **)

        return instance.render_in(&) if block_given?
        return instance if name.nil?

        instances[name] ||= instance
      end

      def store(name, type, *, **, &)
        klass = @controller.element_class_for(type)
        instances[name] = klass.new(name, *, **, &)
      end

      def fetch(name, *, **kwargs)
        instances[name] || begin
          name, type, config = fetch_from_controller(name)
          options = @controller.class.element_settings[name]&.merge(kwargs) || kwargs
          store(name, type, *, **options, &config)
        end
      end

      alias [] fetch

      def respond_to?(name)
        instances.key?(name) || fetch_from_controller(name)
      rescue NotFound
        false
      end

      def rendered?(name)
        !!instances[name]&.rendered?
      end

      def respond_to_missing?(name, *)
        respond_to?(name)
      end

      def key?(name)
        respond_to?(name)
      end

      def method_missing(name, *, **, &)
        return respond_to?(name[0..-2]) if name.end_with?('?')

        name, mandatory = name[0..-2], true if name.end_with?('!')
        instance = fetch(name, *, **)

        block_given? ? instance.render_in(&) : instance
      rescue NotFound => e
        raise(e) if mandatory

        Elements.logger.warn("Element #{name} not found in #{@controller.class}")
        nil
      end

      def inspect
        "#<#{Registry} for #{@controller.class.name} @instances=#{instances.keys}>"
      end

      protected

        def instances
          Context.elements ||= {}
        end

        def fetch_from_controller(name)
          name = name.underscore.to_sym if name.is_a?(String)

          current = @controller.class
          while current < Controller
            entry = current.elements&.[](name)
            return entry if entry

            if (orig_name = current.element_aliases[name])
              entry = current.elements&.[](orig_name)
              return entry if entry
            end

            current = current.superclass
          end

          raise NotFound, "Element #{name} not found in #{@controller.class}"
        end

    end
  end
end
