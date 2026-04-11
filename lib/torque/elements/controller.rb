# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Controller
    module Controller
      extend ActiveSupport::Concern

      included do
        helper_method :element_helper_name, :element_constructor_for, :elements_i18n_keys_for
        delegate :element_constructor_for, to: :class
      end

      class_methods do
        attr_reader :elements

        def element(name, of_type:, **options, &definition)
          raise ArgumentError, +'A definition block must be provided' unless block_given?

          klass = of_type.is_a?(Class) ? of_type : element_constructor_for(of_type)
          valid = klass.is_a?(Class) && klass <= Torque::Elements::Base
          raise ArgumentError, "#{of_type} is not a valid element reference" unless valid

          name = name.underscore.to_sym if name.is_a?(::String)

          change_element(name, **options)
          (@elements ||= {})[name] = lambda do |controller, *args, **kwargs|
            kwargs = inherited_element_settings(name).merge(kwargs)
            klass.new(name, controller, *args, **kwargs, &definition)
          end
        end

        def change_element(name, **options)
          name = name.underscore.to_sym if name.is_a?(::String)
          element_settings[name] = inherited_element_settings(name).merge!(options)
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

      def element_helper_name(name)
        "#{controller_name}_#{name}"
      end

      def elements_i18n_keys_for(*)
        ['%<name>s.%<type>s.%<id>s', '%<name>s.%<id>s']
      end

      def with_elements_context(element, render_context = view_context, **extra, &block)
        RenderingContext.with(element: element, view_context: render_context, **extra, &block)
      end
    end
  end
end
