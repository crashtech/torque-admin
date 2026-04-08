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
          (result[part] ||= []).push(*content)
        end
        result
      end

      def each_value(input, part = :content, &block)
        return unless PARTS.include?(part)

        case input
        when NilClass
          # Do nothing for nil values
        when Hash
          input.each { |key, value| each_value(value, key, &block) }
        when Enumerable
          iter = part == :prepend ? :reverse_each : :each
          input.send(iter) { |value| each_value(value, part, &block) }
        else
          block.call(part, input)
        end
      end
    end
  end
end
