# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Conditional Handler
    class Conditional < BaseHandler
      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(value)
        return if value.nil?

        all_values(value).nil?
      rescue Interrupt
        false
      end

      def all_values(input)
        queue = [input]

        until queue.empty?
          current = queue.shift

          case input
          when NilClass, TrueClass
            # Do nothing for nil or true values
          when FalseClass
            raise Interrupt
          when Enumerable
            queue.concat(current)
          when Method
            queue.push(current.call)
          when Proc
            view_context.instance_exec(&current)
          else
            queue.push(!!current)
          end
        end
      end
    end
  end
end
