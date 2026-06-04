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

      # TODO: For better performance, turn this into an iterative method instead of recursive
      def each_value(input, part = :content, &)
        case input
        when NilClass
          # Do nothing for nil values
        when Hash
          input.each { |key, value| each_value(value, key, &) if PARTS.include?(key) }
        when Enumerable
          iter = part == :before ? :reverse_each : :each
          input.send(iter) { |value| each_value(value, part, &) }
        when Method
          each_value(input.call, part, &)
        when Proc
          each_value(view_context.instance_exec(&input), part, &)
        when Symbol
          if view_context.respond_to?(input)
            each_value(view_context.public_send(input), part, &)
          else
            yield(part, input.to_s)
          end
        else
          yield(part, input)
        end
      end
    end
  end
end
