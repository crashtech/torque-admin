# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Controller
    module Controller
      extend ActiveSupport::Concern

      included do
        helper_method :elements, :elements_i18n_keys_for
      end

      class_methods do
        attr_reader :elements

        def element_helper_name(name)
          "#{controller_name}_#{name}"
        end

        def element(name, as:, **options, &definition)
          raise ArgumentError, +'A definition block must be provided' unless block_given?
          raise ArgumentError, "Element of type #{as} does not exist" unless (klass = Elements.type_for(as))

          name = name.underscore.to_sym if name.is_a?(::String)
          helper_name = options.delete(:helper_method) || element_helper_name(name)

          (@elements ||= {})[name] = ->(context, **kwargs, &block) do
            klass.new(name, context, helper_name, definition, **options, **kwargs, &block)
          end
        end
      end

      protected

        def elements
          @elements ||= Registry.new(self)
        end

        def elements_i18n_keys_for(*)
          ['%<name>s.%<type>s.%<id>s', '%<name>s.%<id>s']
        end
    end
  end
end
