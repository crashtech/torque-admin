# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Content Handler
    class ContentHandler < BaseHandler
      PARTS = %i[prepend before content after append].to_set.freeze

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
      def each_value(input, part = :content, &block)
        case input
        when NilClass
          # Do nothing for nil values
        when Hash
          input.each { |key, value| each_value(value, key, &block) if PARTS.include?(key) }
        when Enumerable
          iter = part == :prepend ? :reverse_each : :each
          input.send(iter) { |value| each_value(value, part, &block) }
        when Method
          each_value(input.call, part, &block)
        when Proc
          each_value(view_context.instance_exec(&input), part, &block)
        when Symbol
          if view_context.respond_to?(input)
            each_value(view_context.public_send(input), part, &block)
          else
            block.call(part, input.to_s)
          end
        else
          block.call(part, input)
        end
      end
    end
  end
end
