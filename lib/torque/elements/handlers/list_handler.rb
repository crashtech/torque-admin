# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \List Handler
    class ListHandler < RefHandler
      def initialize(separator: ' ', nested_separator: '-', unique: true)
        @separator = separator
        @nested_separator = nested_separator
        @unique = unique
      end

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(values)
        result = @unique ? Set.new : []

        each_value(values) do |value, key = nil|
          case value
          when String then result << value
          when TrueClass then result << key.to_s
          when FalseClass then result.delete(key.to_s)
          end
        end

        result.join(@separator)
      end

      # TODO: For better performance, turn this into an iterative method instead of recursive
      def each_value(input, prefix: '', &)
        case input
        when NilClass
          # Do nothing for nil values
        when Hash
          input.each { |key, value| each_value(value, prefix: prefix + key.to_s + @nested_separator, &) }
        when Enumerable
          input.each { |value| each_value(value, prefix: prefix, &) }
        when TrueClass, FalseClass
          yield(input, prefix.chomp(@nested_separator)) unless prefix.empty?
        when Symbol
          each_value(deref(input), prefix: prefix, &)
        else
          if (input = input.to_s).include?(@separator)
            input.split(@separator).each { |value| yield("#{prefix}#{value}") }
          elsif !input.empty?
            yield("#{prefix}#{input}")
          end
        end
      end
    end
  end
end
