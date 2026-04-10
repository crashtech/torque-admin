# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \UI Helpers
    class UiBuilder
      CONTENT_OPTIONS = (ContentHandler::PARTS - [:content]).map(&:to_s).map(&:freeze).freeze

      attr_reader :view_context

      delegate :attribute_name, to: 'Torque::Elements'
      delegate :presets, to: :class
      delegate_missing_to :view_context

      class << self
        def new(context, framework: nil)
          return super if self != UiBuilder

          raise MissingFrameworkError, <<~MSG.squish unless (klass = framework_classes[normalize_name(framework)])
            No UI framework named '#{framework}'.
            Please make sure it is defined and added to the list of supported frameworks.
          MSG

          klass.new(context)
        end

        def presets
          @presets ||= Hash.new { |hash, key| hash[key] = {} }
        end

        def add_preset(source, name, **options)
          presets[source.to_sym][name.to_sym] = options
        end

        def import_presets(source)
          source.each { |name, values| presets[name].merge!(values) }
        end

        def import_presets_from(mod, method_name: :elements_presets)
          mod.try(:compile_elements_helpers!)
          import_presets(mod.elements_presets) if mod.respond_to?(method_name)
        end

        ## Framework management

        def framework_enabled?(name)
          framework_classes.key?(normalize_name(name))
        end

        def enable_framework(name, base: UiBuilder)
          add_framework(name, Elements.ui_framework_helper(name), base: base)
        end

        def add_framework(name, mod, base: UiBuilder)
          raise ::ArgumentError, <<~MSG.squish unless base <= UiBuilder
            #{base} class must be a subclass of UiBuilder.
          MSG

          framework_classes[normalize_name(name)] = Class.new(base).tap do |klass|
            klass.include(mod)
          end
        end

        def name_of(instance = self)
          framework_classes.key(instance)
        end

        alias framework_name name_of

        def inspect
          if eql?(UiBuilder)
            "#<Torque::Elements::UiBuilder (base class) @frameworks=[#{framework_classes.keys.join(', ')}]>"
          else
            "#<Torque::Elements::UiBuilder (base class) @framework=#{framework_name}>"
          end
        end

        # Hook into the include process to import presets
        def include(*modules)
          modules.each do |mod|
            mod.included_modules.each(&method(:import_presets_from))
            import_presets_from(mod)
          end

          super
        end

        protected

          def normalize_name(name)
            name.to_s.underscore.freeze
          end

          def framework_classes
            @@framework_classes ||= {}
          end
      end

      def initialize(view_context)
        @view_context = view_context
      end

      def framework_name
        self.class.name_of(self.class) || 'NONE'
      end

      def collapse_options(options)
        options.each_with_object({}) do |(key, value), collapsed|
          collapsed[key] = Elements.find_attribute(key).collapse(value)
        end
      end

      def combine_option(key, current, value)
        current[key] = Elements.find_attribute(key).combine(current[key], value)
      end

      def combine_options(current, options)
        options&.each_with_object(current) { |(key, value), combined| combine_option(key, combined, value) }
      end

      def build_options(*settings)
        settings.flatten.each_with_object({}) do |input, options|
          combine_options(options, flatten_options(input)) if input.present?
        end
      end

      def flatten_options(options, prefix = '')
        options.presence&.each_with_object({}) do |(key, value), result|
          attr = attribute_name("#{prefix}#{key}")
          if value.is_a?(Hash) && !Elements.static_attribute?(attr)
            result.merge!(flatten_options(value, "#{prefix}#{key}-"))
          elsif CONTENT_OPTIONS.include?(attr)
            (result['@content'] ||= {})[attr.to_sym] = value
          else
            result[attr] = value
          end
        end
      end

      def render_content_tag(tag_name, content = nil, options = {}, &block)
        content = view_context.capture(&block) if block_given?
        combine_option('@content', options, content) if content.present?
        render_tag(tag_name, options, with_content: true)
      end

      def render_tag(tag_name, options = {}, with_content: false)
        options = collapse_options(options)
        left, *inner, right = options.delete('@content')&.values_at(:prepend, :before, :content, :after, :append)
        content = view_context.safe_join(inner.flatten) if with_content && inner.present?
        view_context.safe_join([*left, tag_builder.public_send(tag_name, *content, **options), *right])
      end

      def split_options_properties(source, property_list, preset_list = nil, kwargs = {})
        properties = {}.with_indifferent_access
        options = (fetch_presets(:default, *preset_list, from: source) << kwargs).each_with_object({}) do |input, result|
          next if input.blank?

          properties.merge!(input.extract!(*property_list))
          combine_options(result, flatten_options(input))
        end

        [options, properties]
      end

      def fetch_presets(*list, from:)
        return [] if (source = presets[from]).nil?

        list.filter_map { |name| source[name].dup }
      end

      def inspect
        "#<Torque::Elements::UiBuilder @framework=#{framework_name}>"
      end

      protected

        def tag_builder
          view_context.tag
        end
    end
  end
end
