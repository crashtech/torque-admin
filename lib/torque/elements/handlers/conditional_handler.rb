# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Conditional Handler
    #
    # Reduces every value accumulated for a conditional attribute into a single boolean. The operator
    # decides how multiple values combine, while the polarity of that boolean is applied by the render
    # site, so +if+/+remove_unless+ use +:and+ and +unless+/+remove_if+ use +:or+.
    class ConditionalHandler < BaseHandler
      OPERATORS = %i[and or].freeze

      def initialize(operator = :and)
        raise ::ArgumentError, <<~MSG.squish unless OPERATORS.include?(operator)
          Invalid operator #{operator.inspect}, valid operators are: #{OPERATORS.map(&:inspect).join(', ')}.
        MSG

        @operator = operator
      end

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(value)
        return if value.nil?

        expected = @operator == :and
        each_value(value) { |result| return !expected unless result == expected }
        expected
      end

      def each_value(input, &)
        queue = [input]

        until queue.empty?
          current = queue.shift

          case current
          when NilClass then next
          when TrueClass, FalseClass then yield(current)
          when Enumerable then queue.concat(current.to_a)
          when *PROC_CLASSES then queue.push(collapse_proc(current))
          when Symbol then queue.push(resolve(current))
          else yield(true)
          end
        end
      end

      private

        # TODO: We should probably move this to base. That way, it might be easier to add support for templates later on
        def resolve(name)
          raise ::NameError, <<~MSG.squish unless view_context.respond_to?(name)
            Condition #{name.inspect} is not available on #{view_context.class.name}.
          MSG

          view_context.public_send(name)
        end
    end
  end
end
