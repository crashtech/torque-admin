# frozen_string_literal: true

module Torque
  module Elements
    class ListHandler
      def initialize(separator: ' ', nested_separator: '-', unique: true)
        @separator = separator
        @nested_separator = nested_separator
        @unique = unique
      end

      def call(*values)
        result = @unique ? Set.new : []

        each_value(values.flatten) do |key, value|
          case value
          when String then result << value
          when TrueClass then result << key.to_s
          when FalseClass then result.delete(key.to_s)
          end
        end

        result.to_a.join(@separator)
      end

      private

        def each_value(input, prefix: '', &block)
          case input
          when TrueClass, FalseClass
            block.call(prefix.chomp(@nested_separator), input) unless prefix.empty?
          when String
            input.split(@separator).each do |part|
              block.call(nil, prefix + part.strip)
            end
          when Symbol
            # TODO: Figure out how to handle aliases
            # each_value(Elements.context.aliases[input], prefix: prefix, &block)
          when Hash
            input.each do |k, value|
              each_value(value, prefix: prefix + k.to_s + @nested_separator, &block)
            end
          when Enumerable
            input.each do |value|
              each_value(value, prefix: prefix, &block)
            end
          end
        end
    end
  end
end
