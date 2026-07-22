# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Traverse
    class Traverse
      include Enumerable

      attr_reader :stack, :current, :depth

      def initialize(list, max_depth: nil, min_depth: nil)
        @stack = [[list, 0, 1]]
        @max_depth = max_depth || Float::INFINITY
        @min_depth = min_depth || 0
      end

      def each
        return self unless block_given?

        until @stack.empty?
          next if stack_next
          break unless current || unstack

          item = fetch_next
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

          item = fetch_next
          next unless depth >= @min_depth

          result = yield(item, content)
          @content.last << result unless result.nil?
        end

        @content.pop.presence
      end

      private

        def stack_next
          load_next
          return unless current&.branch?

          next_depth = depth + (current.ignore_depth? ? 0 : 1)
          return if next_depth > @max_depth

          stack << [current.children, 0, next_depth]
        end

        def fetch_next
          ref = stack.last
          item = ref[0][ref[1]]
          ref[1] += 1
          item
        end

        def load_next
          ref = stack.last
          @current = ref[0][ref[1]]
          @depth = ref[2]
        end

        def unstack
          stack.pop
          @depth = stack.last&.last
        end
    end
  end
end
