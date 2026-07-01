# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Map Handler
    class MapHandler < BaseHandler
      def initialize(separator: ',', nested_separator: '_', format: nil, as_json: true)
        @separator = separator
        @nested_separator = nested_separator
        @format = format
        @as_json = as_json
      end

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(values)
        result = {}

        each_value(values) do |key, value|
          if value
            result[format(key)] = value
          else
            result.delete(format(key))
          end
        end

        return JSON.generate(result) if @as_json

        result.map { |parts| parts.join(':') }.join(@separator)
      end

      def each_value(input, &)
        stack = [[input, '']]

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
            yield(current_prefix.chomp(@nested_separator), current) unless current_prefix.empty?
          else
            str = current.to_s
            if current_prefix.empty?
              split_string(str, &)
            else
              yield(current_prefix.chomp(@nested_separator), str.strip)
            end
          end
        end
      end

      def split_string(value, &)
        return JSON.parse(value).each_pair(&) if @as_json

        Crass.parse_properties(value, preserve_comments: false).each do |node|
          yield(node[:name], node[:value]) if node[:node] == :property
        end
      end
    end
  end
end
