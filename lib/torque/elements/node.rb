# frozen_string_literal: true

require_relative 'nodes/rendering'
require_relative 'nodes/textify'

module Torque
  module Elements
    # = Torque Elements \Core Node
    class Node
      CLASS_TYPES = {
        link: 'Torque::Elements::LinkNode',
      }

      attr_reader :id, :type, :parent, :settings, :options

      class_attribute :settings, instance_accessor: false, default: [].freeze

      delegate :[], :[]=, to: :options
      delegate :tag, to: '::Torque::Elements::Context.view_context'

      include Rendering
      include Textify

      alias to_s render
      alias to_str render
      alias html_safe render

      append_render_handler do |node, element = nil, ui: Context.view_context.try(:ui)|
        name = ui&.element_helper_name(node, element&.type)
        [:render_with_helper, ui.method(name)] if name && ui&.respond_to?(name)
      end

      append_render_handler do |node, element = nil, base: Context.view_context|
        name = base.element_helper_name(node, element&.type)
        [:render_with_helper, base.method(name)] if name && base&.respond_to?(name)
      end

      class << self
        protected

          def settings=(values)
            super(Array.wrap(values).map(&:to_sym).freeze)
          end
      end

      def initialize(id, type, parent = nil, **options)
        element, parent = parent, nil if parent.is_a?(Base)
        element ||= parent&.instance_variable_get(:@element)

        @id = id
        @type = type.to_sym
        @parent = parent
        @element = element if element

        extract_settings(options)
        @options = options
      end

      def initialize_copy(other)
        super

        @parent = nil
        @options = other.options.deep_dup
        @settings = other.settings.dup if other.settings
        remove_instance_variable(:@children)
      end

      def change(options)
        (@options['@append'] ||= []) << options
      end

      alias append change

      def change!(options)
        @options.merge!(options)
      end

      def sanitized_options
        return @options if @options.frozen?

        sanitized_options!
        @options.freeze
      end

      def children
        @children ||= []
      end

      def branch?
        defined?(@children) && !@children.empty?
      end

      def leaf?
        !branch?
      end

      def of_type?(value)
        type == value.to_sym
      end

      alias =~ of_type?

      def inspect
        "#<#{self.class.name} id=#{id.inspect} type=#{type.inspect} children=#{children.size} options=#{options.inspect}>"
      end

      protected

        def extract_settings(options)
          keys = @type == :root ? @element&.element_settings : self.class.settings
          values = options.extract!(*Core::Nodes::POSITION_OPTIONS, *keys)
          @settings = values if values.present?
        end
    end
  end
end
