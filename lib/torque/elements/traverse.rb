# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Traverse
    class Traverse
      include Enumerable

      attr_reader :stack, :current, :depth

      def initialize(list, max_depth: nil, min_depth: nil)
        @stack = [[list.to_enum, 1]]
        @max_depth = max_depth || Float::INFINITY
        @min_depth = min_depth || 0
      end

      def each
        return self unless block_given?

        until @stack.empty?
          next if stack_next
          break unless current || unstack

          item = stack.last.first.next
          yield item if depth >= @min_depth
        end
      end

      def with_content
        return to_enum(:with_content) unless block_given?

        @content = [[]]
        until @stack.empty?
          next @content << [] if stack_next

          content = !current && unstack ? @content.pop : nil
          break unless depth

          item = stack.last.first.next
          @content.last << yield(item, content) if depth >= @min_depth
        end

        yield(nil, @content.pop)
      end

      private

        def stack_next
          load_next
          return unless current&.branch?

          next_depth = depth + (current.skip_depth? ? 0 : 1)
          return if next_depth > @max_depth

          stack << [current.children.to_enum, next_depth]
        end

        def load_next
          @current = stack.last.first.peek rescue nil
          @depth = stack.last.last
        end

        def unstack
          stack.pop
          @depth = stack.last&.last
        end
    end
  end
end
