# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Controller
    module Controller
      extend ActiveSupport::Concern

      included do
        helper_method :elements, :element_helper_name, :elements_i18n_keys_for
      end

      class_methods do
        attr_reader :elements

        def element(name, as:, **options, &definition)
          raise ArgumentError, +'A definition block must be provided' unless block_given?

          klass = as.is_a?(Class) ? as : element_constructor_for(as)
          valid = klass.is_a?(Class) && klass <= Torque::Elements::Base
          raise ArgumentError, "#{as} is not a valid element reference" unless valid

          name = name.underscore.to_sym if name.is_a?(::String)

          change_element(name, **options)
          (@elements ||= {})[name] = lambda do |controller, *args, **kwargs|
            kwargs = inherited_element_settings(name).merge(kwargs)
            klass.new(name, controller, definition, *args, **kwargs)
          end
        end

        def change_element(name, **options)
          name = name.underscore.to_sym if name.is_a?(::String)
          inherited_element_settings(name).merge!(options)
        end

        def element_constructor_for(name)
          name = name.to_s unless name.is_a?(::String)
          name = name.camelize
          name += 'Element' unless name.end_with?('Element')
          name.safe_constantize
        end

        private

          def inherited_element_settings(name)
            if (current = @element_settings.try(:[], name))
              current
            elsif superclass.respond_to?(:inherited_element_settings)
              superclass.inherited_element_settings(name)
            else
              {}
            end
          end

          def element_settings
            @element_settings ||= {}
          end
      end

      def elements
        @elements ||= Registry.new(self)
      end

      def element_helper_name(name)
        "#{controller_name}_#{name}"
      end

      def elements_i18n_keys_for(*)
        ['%<name>s.%<type>s.%<id>s', '%<name>s.%<id>s']
      end
    end
  end
end
