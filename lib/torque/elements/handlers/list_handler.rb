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

        result.join(@separator).presence
      end

      def each_value(input, prefix: '', &)
        stack = [[input, prefix]]

        until stack.empty?
          current, current_prefix = stack.pop

          case current
          when NilClass
            # Do nothing for nil values
          when Hash
            current.reverse_each { |key, value| stack.push([value, current_prefix + key.to_s + @nested_separator]) }
          when Enumerable
            current.reverse_each { |value| stack.push([value, current_prefix]) }
          when TrueClass, FalseClass
            yield(current, current_prefix.chomp(@nested_separator)) unless current_prefix.empty?
          when Symbol
            stack.push([deref(current), current_prefix])
          when *PROC_CLASSES
            stack.push([collapse_proc(current), current_prefix])
          else
            str = current.to_s
            if str.include?(@separator)
              str.split(@separator).each { |value| yield("#{current_prefix}#{value}") }
            elsif !str.empty?
              yield("#{current_prefix}#{str}")
            end
          end
        end
      end
    end
  end
end
