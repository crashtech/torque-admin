# frozen_string_literal: true

require_relative 'basic_node'
require_relative 'nodes/textify'

module Torque
  module Elements
    # = Torque Elements \Core Node
    #
    # The logical rung of the node ladder: identity (id), settings, i18n/textify and
    # context changes on top of the physical BasicNode.
    class Node < BasicNode
      POSITION_OPTIONS = %i[insert_after insert_before prepend_to append_to].freeze

      TYPES = {
        basic: 'Torque::Elements::BasicNode',
        column: 'Torque::Elements::ColumnNode',
        link: 'Torque::Elements::LinkNode',
      }.freeze

      attr_reader :id, :settings

      include Textify

      class_attribute :settings_keys, instance_accessor: false, default: [].freeze

      class << self
        def setting(*keys)
          self.settings_keys += keys.flatten.map(&:to_sym)
        end

        protected

          def settings_keys=(values)
            self.__class_attr_settings_keys = Array.wrap(values).map(&:to_sym).freeze
          end
      end

      def initialize(id, type, **options)
        @id = id
        extract_settings(options)
        super(type, **options)
      end

      def initialize_copy(other)
        super
        @settings = other.settings.dup if other.settings
      end

      def fetch_setting(key, default = nil)
        defined?(@settings) && @settings ? @settings.fetch(key, default) : default
      end

      def render_name
        custom = fetch_setting(:render)
        return custom.to_sym if custom.is_a?(Symbol) || custom.is_a?(String)

        (el = element) ? :"#{el.type}_#{type}" : type
      end

      def reset_render!
        super
        remove_instance_variable(:@parts) if defined?(@parts)
      end

      def render_part(part, *args, **options)
        cache = (@parts ||= {})
        cacheable = args.empty? && options.empty?
        return cache[part] if cacheable && cache.key?(part)

        result = invoke_part_render(part, args, options)
        cache[part] = result if cacheable
        result
      end

      def dispatch_part(part, *args, **options)
        name = :"#{render_name}_#{part}"
        handler = resolve_dispatch_handler(name)

        raise ArgumentError, <<~MESSAGE unless handler
          No render handler found for part '#{part}' of node '#{id}' of type '#{type}'
          Attempted: `render_#{name}` and `ui.#{name}`
        MESSAGE

        handler.call(*args, **options)
      end

      def inspect
        "#<#{self.class.name} #{<<~INSPECT.chomp}>".squish
          id=#{id.inspect}
          type=#{type.inspect}
          children=#{children.size}
          options=#{options.inspect}
        INSPECT
      end

      protected

        def sanitized_options!
          super
          apply_context_changes
          textify_options
        end

        def apply_context_changes(as = id)
          return unless (el = element) && el.name

          Context.apply_changes(el.name, as, @options)
          Context.deep_extract_properties(extraction_settings_keys, @options) do |props, _|
            merge_settings(props) if props.present?
          end
        end

        def render_override
          custom = fetch_setting(:render)
          custom if custom.is_a?(Proc)
        end

        def invoke_part_render(part, args, options)
          el = element
          element_method = :"render_#{type}_#{part}"
          return el.send(element_method, self, *args, **options) if el&.respond_to?(element_method)

          dispatch_part(part, *args, **options)
        end

        def default_render(body, options)
          raise ArgumentError, <<~MESSAGE
            No render handler found for node '#{id}' of type '#{type}'
            #{"From '#{element.name}' element" if element}
            Attempted: #render_#{type} on the element, `render_#{render_name}` from helpers, and `ui.#{render_name}`
          MESSAGE
        end

        def merge_settings(values)
          (@settings ||= {}).merge!(values)
        end

        def extract_settings(options)
          values = options.extract!(*POSITION_OPTIONS, :render, *extraction_settings_keys)
          @settings = values if values.present?
        end

        def extraction_settings_keys
          self.class.settings_keys
        end

        def content_traverse_options
          settings&.slice(:max_depth, :min_depth) || {}
        end
    end
  end
end
