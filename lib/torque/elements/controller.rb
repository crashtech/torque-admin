# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Controller
    module Controller
      extend ActiveSupport::Concern

      included do
        helper_method :element_helper_name, :element_class_for, :element_class_name, :change_element, :elements_i18n_keys_for
        delegate :element_class_name, :element_class_for, :change_element, to: :class
      end

      class_methods do
        attr_reader :elements

        def element(name, of_type:, **, &config)
          raise ArgumentError, +'A config block must be provided' unless block_given?

          name = name.underscore.to_sym if name.is_a?(::String)
          change_element(name, **)

          (@elements ||= {})[name] = [name, of_type, config]
        end

        def change_element(name, options = nil)
          return unless options

          name = name.underscore.to_sym if name.is_a?(::String)
          element_settings[name] = inherited_element_settings(name).merge!(options)
        end

        def element_class_for(type)
          klass = type.is_a?(Class) ? type : element_class_name(type)
          return klass if klass.is_a?(Class) && klass <= Torque::Elements::Base

          raise ArgumentError, "#{type} is not a valid element reference"
        end

        def element_class_name(name)
          name = name.to_s unless name.is_a?(::String)
          name = name.camelize
          name += 'Element' unless name.end_with?('Element')
          name.safe_constantize
        end

        def inherited_element_settings(name)
          if (current = @element_settings.try(:[], name))
            current
          elsif superclass.respond_to?(:inherited_element_settings)
            superclass.inherited_element_settings(name)
          else
            {}
          end
        end

        private

          def element_settings
            @element_settings ||= {}
          end
      end

      def element_helper_name(element, node)
        "render_#{element.type}_#{node.type}".chomp('_root')
      end

      def elements_i18n_keys_for(*)
        ['%<name>s.%<type>s.%<id>s', '%<name>s.%<id>s']
      end
    end
  end
end
