# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Content Handler
    class ContentHandler < BaseHandler
      PARTS = %i[before prepend content append after].to_set.freeze

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(value)
        result = {}
        each_value(value) do |part, content|
          (result[part] ||= []) << content
        end
        result
      end

      def each_value(input, part = :content, &)
        stack = [[part, input]]

        until stack.empty?
          current_part, current = stack.pop
          next unless PARTS.include?(current_part)

          case current
          when NilClass, TrueClass, FalseClass
            # Do nothing for nil these types of values
          when Hash
            if (render = current[:render]).present?
              yield(current_part, view_context.capture { view_context.render(render, current.except(:render)) })
            else
              stack += current.to_a.reverse
            end
          when Enumerable
            push_iter = current_part == :before ? :each : :reverse_each
            current.send(push_iter) { |value| stack.push([current_part, value]) }
          when *PROC_CLASSES
            stack.push([current_part, collapse_proc(current)])
          when Symbol
            if view_context.respond_to?(current)
              stack.push([current_part, view_context.public_send(current)])
            else
              yield(current_part, current.to_s)
            end
          else
            yield(current_part, current.to_s)
          end
        end
      end
    end
  end
end
