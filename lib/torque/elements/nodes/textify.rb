# frozen_string_literal: true

module Torque
  module Elements
    class Node
      # = Torque Elements \Textify Node
      module Textify
        extend ActiveSupport::Concern

        attr_writer :label_key

        included do
          class_attribute :label_key, instance_accessor: false, default: :label
          class_attribute :text_attributes, instance_accessor: false, default: %i[label alt placeholder title].freeze
        end

        class_methods do
          protected

            def label_key=(value)
              super(value.to_sym)
            end

            def text_attributes=(values)
              super(Array.wrap(values).map(&:to_sym).freeze)
            end
        end

        def label_key
          defined?(@label_key) ? @label_key : self.class.label_key
        end

        def text_for(option, default: nil)
          if FalseClass === (current = @options[option])
            @options.delete(option)
            return
          end

          return current if current.is_a?(String)

          @options[option] ||= default.is_a?(String) ? default : begin
            raise ::I18n::MissingTranslationData unless defined?(@element)

            values = { name: @element.send(:i18n_name), element_type: @element.type, type: @type, id: @id.underscore }
            keys = map_i18n_keys(option) { |key| format(key, values).to_sym }
            ::I18n.translate(keys.shift, default: keys, raise: true, **@element.i18n_options)
          rescue ::I18n::MissingTranslationData
            text_for_fallback(default, option) if default.present?
          end
        end

        def respond_to_missing?(method, *)
          method == label_key || super
        end

        def method_missing(method, *, **, &)
          method == label_key ? text_for(method) : super
        end

        protected

          def sanitized_options!
            super
            textify_options
          end

          def textify_options
            @options.extract!(*self.class.text_attributes).each do |key, value|
              text_for(key, default: value) if value
            end
          end

          def text_for_fallback(value, key)
            (defined?(@element) && @element.fallback_text_for(key, value, self)) ||
              value.to_s.underscore.humanize
          end

          def map_i18n_keys(option, primary: label_key, keys: @element.send(:i18n_keys))
            keys.flat_map do |key|
              next yield(key) if option.nil?

              value = yield("#{key}.#{option}")
              next value if option != primary

              [value, yield(key)]
            end
          end

      end
    end
  end
end
