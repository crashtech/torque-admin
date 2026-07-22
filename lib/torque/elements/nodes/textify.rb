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
          def template_safe_textify?
            Elements.i18n_safe_template && Context.view_context.try(:template_render_context?)
          end


          def i18n_keys
            @i18n_keys ||= Context.view_context.elements_i18n_keys
          end
          def translate(element, element_type, type, id, property, primary: false, attribute: false, titlelize: false, default: nil)
            values = { name: element, element_type:, type:, id: }

            keys = Context.view_context.elements_i18n_keys
            keys = map_i18n_keys(property, keys, primary:) { |key| format(key, values).to_sym }
            ::I18n.translate(keys.shift, default: keys, raise: true)
          rescue ::I18n::MissingTranslationData => error
            fallback = nil
            if primary
              fallback ||= Context.view_context.controller.try(:implicit_attribute_name, id).presence if attribute
              fallback ||= Context.view_context.try(:implicit_translate_node, element_type, type, id).presence
            end
            fallback ||= default.to_s.underscore.public_send(titlelize ? :titleize : :humanize) if default.is_a?(Symbol)
            fallback || (default if default.is_a?(String)) || error.message
          end

          protected

            def label_key=(value)
              super(value.to_sym)
            end

            def text_attributes=(values)
              super(Array.wrap(values).map(&:to_sym).freeze)
            end

            def map_i18n_keys(option, keys, primary: false)
              keys.flat_map do |key|
                next yield(key) if option.nil?

                value = yield("#{key}.#{option}")
                next value if primary

                [value, yield(key)]
              end
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
            if defined?(@element) && Node.template_safe_textify?
              template_safe_text_for(option, default)
            else
              Node.translate(
                @element&.send(:i18n_name),
                @element&.type,
                @type,
                @id.underscore,
                option,
                primary: option == label_key,
                attribute: @element&.implicit_attribute_for?(option, self),
                titlelize: @element&.titlelize_text_for?(option, self),
                default: default,
              )
            end
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

          def template_safe_text_for(option, default)
            Context.view_context.append(<<~RUBY.squish)
              Torque::Elements::Node.translate(
                "#{@element.send(:i18n_name)}",
                "#{@element.type}",
                "#{@type}",
                "#{@id.underscore}",
                "#{option}",
                primary: #{(option == label_key).inspect},
                attribute: #{@element.implicit_attribute_for?(option, self).present?.inspect},
                titlelize: #{@element.titlelize_text_for?(option, self).present?.inspect}
                #{", default: :#{default}" if default.is_a?(Symbol)}
              )
            RUBY
          end

      end
    end
  end
end
