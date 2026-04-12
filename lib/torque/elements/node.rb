# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Core Node
    class Node
      attr_reader :id, :type, :parent, :options

      def initialize(id, type, parent, skip_depth = false, **options)
        @id = id
        @type = type.to_sym
        @parent = parent

        @options = options.symbolize_keys
        @skip_depth = skip_depth
      end

      def children
        @children ||= []
      end

      def leaf?
        @children.nil?
      end

      def branch?
        !leaf?
      end

      def of_type?(value)
        type == value.to_sym
      end

      alias =~ of_type?

      def skip_depth?
        @skip_depth
      end

      def inspect
        "#<#{self.class.name} id=#{id.inspect} type=#{type.inspect}>"
      end
    end
  end
end
