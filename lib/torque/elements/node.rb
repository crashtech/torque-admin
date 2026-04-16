# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Core Node
    class Node
      attr_reader :id, :type, :parent, :options

      delegate :[], :[]=, to: :options

      def initialize(id, type, options = {}, element: nil, parent: nil, skip_depth: false)
        @id = id
        @type = type.to_sym
        @element = element
        @parent = parent

        @options = options.symbolize_keys
        @skip_depth = skip_depth
      end

      def change(options)
        (@options['@append'] ||= []) << options
      end

      alias append change

      def change!(options)
        @options.merge!(options)
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

      def skip_depth?
        @skip_depth
      end

      def render
        raise "No element assigned to node #{id.inspect}" unless @element

        @element.render_node(self)
      end

      def render_with(options)
        @options.with(options) { render }
      end

      alias to_s render
      alias to_str render
      alias html_safe render

      def inspect
        "#<#{self.class.name} id=#{id.inspect} type=#{type.inspect}>"
      end
    end
  end
end
