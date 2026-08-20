# frozen_string_literal: true

require_relative 'nodes/basic_render'

module Torque
  module Elements
    # = Torque Elements \Basic Node
    #
    # The purely physical rung of the node ladder: a tag with handler-managed options,
    # children, and content. No id, no settings, no i18n. Renders through the same helper
    # dispatch as every other node, falling back to a plain content tag.
    class BasicNode
      attr_reader :type, :options
      attr_accessor :parent, :element
      attr_writer :content

      delegate :[], :[]=, to: :options
      delegate :tag, to: '::Torque::Elements::Context.view_context'

      include BasicRender

      def initialize(type, **options)
        @type = type.to_sym
        @options = options
      end

      def initialize_copy(other)
        super

        @parent = nil
        @element = nil
        @options = other.options.deep_dup
        remove_instance_variable(:@children) if defined?(@children)
        remove_instance_variable(:@content) if defined?(@content)
        remove_instance_variable(:@to_s) if defined?(@to_s)
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
        value.is_a?(Array) ? type.in?(value) : type == value
      end

      alias =~ of_type?

      def change(options)
        (@options['@append'] ||= []) << options
      end

      alias append change

      def change!(options)
        @options.merge!(options)
      end

      def ignore_depth?
        defined?(@ignore_depth) && @ignore_depth
      end

      def ignore_depth!
        @ignore_depth = true
      end

      def inspect
        "#<#{self.class.name} type=#{type.inspect} children=#{children.size} options=#{options.inspect}>"
      end
    end
  end
end
