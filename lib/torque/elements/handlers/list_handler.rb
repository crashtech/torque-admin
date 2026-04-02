# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \List Handler
    class ListHandler < BaseHandler
      def initialize(separator: ' ', nested_separator: '-', unique: true)
        @separator = separator
        @nested_separator = nested_separator
        @unique = unique
        super()
      end

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(*values)
        result = @unique ? Set.new : []

        each_value(values.flatten) do |value, key = nil|
          case value
          when String then result << value
          when TrueClass then result << key.to_s
          when FalseClass then result.delete(key.to_s)
          end
        end

        result.to_a.join(@separator)
      end

      def each_value(input, prefix: '', &block)
        case input
        when Hash
          input.each { |key, value| each_value(value, prefix: prefix + key.to_s + @nested_separator, &block) }
        when Enumerable
          input.each { |value| each_value(value, prefix: prefix, &block) }
        when TrueClass, FalseClass
          block.call(input, prefix.chomp(@nested_separator)) unless prefix.empty?
        else
          input.to_s.split(@separator).each { |part| part.strip.presence&.prepend(prefix)&.then(&block) }
        end
      end
    end
  end
end
