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

      # TODO: For better performance, turn this into an iterative method instead of recursive
      def each_value(input, prefix: '', &block)
        case input
        when NilClass
          # Do nothing for nil values
        when Hash
          input.each { |key, value| each_value(value, prefix: prefix + key.to_s + @nested_separator, &block) }
        when Enumerable
          input.each { |value| each_value(value, prefix: prefix, &block) }
        when TrueClass, FalseClass
          block.call(prefix.chomp(@nested_separator), input) unless prefix.empty?
        else
          if prefix.empty?
            split_string(input.to_s, &block)
          else
            block.call(prefix.chomp(@nested_separator), input.to_s.strip)
          end
        end
      end

      def split_string(value, &block)
        return JSON.parse(value).each_pair(&block) if @as_json

        Crass.parse_properties(value, preserve_comments: false).each do |node|
          block.call(node[:name], node[:value]) if node[:node] == :property
        end
      end
    end
  end
end
