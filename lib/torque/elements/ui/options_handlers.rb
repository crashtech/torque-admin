# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Options Helpers
    class UiBuilder
      module OptionsHandlers
        def append_options(options, values)
          list = options['@append'] ||= []
          values.is_a?(Array) ? list.concat(values) : list << values
          options
        end

        def build_options(*settings)
          settings.flatten.each_with_object({}) do |input, options|
            flatten_options!(input) { |key, value| combine_option(key, options, value) }
          end
        end

        def flatten_options(options)
          result = {}
          flatten_options!(options, &result.method(:[]=))
          result
        end

        def combine_options(current, options)
          options&.each_with_object(current) { |(key, value), combined| combine_option(key, combined, value) }
        end

        def combine_option(key, current, value)
          current[key] = Elements.find_attribute(key).combine(current[key], value)
        end

        def collapse_options(options)
          options.each_with_object({}) do |(key, value), collapsed|
            collapsed[key] = Elements.find_attribute(key).collapse(value)
          end
        end

        def flatten_content_option(value, &)
          yield('@content', value)
        end

        def flatten_append_option(value, &)
          value.each do |append|
            append = view_context.collapse_proc(append) if Elements.act_as_proc?(append)
            flatten_options!(append, &)
          end
        end

        def flatten_controller_option(value, &)
          value.each { |controller| controller.to_options(&) }
        end

        def split_options_properties(source, property_list, preset_list = nil, kwargs = {})
          inputs = [kwargs, *fetch_presets(:default, *preset_list, from: source).reverse]
          properties = {}
          options = {}

          Context.deep_extract_properties(property_list, *inputs) do |props, opts|
            flatten_options!(opts) { |key, value| combine_option(key, options, value) }
            properties.merge!(props) if props.present?
          end

          [options, properties]
        end

        def fetch_presets(*list, from:)
          return [] if (source = presets[from]).nil?

          list.filter_map { |name| source[name].dup }
        end

        protected

          def flatten_options!(options, prefix = '', &)
            options&.each do |key, value|
              attr = attribute_name("#{prefix}#{key}")
              if value.is_a?(Hash) && !Elements.static_attribute?(attr)
                flatten_options!(value, "#{prefix}#{key}-", &)
              elsif CONTENT_OPTIONS.include?(attr)
                yield('@content', { key => value })
              elsif attr[0] == '@' && (method_name = SPECIAL_OPTIONS[attr])
                method(method_name).call(value, &)
              else
                yield(attr, value)
              end
            end
          end
      end
    end
  end
end
