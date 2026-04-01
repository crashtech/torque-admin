# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Map Handler
    class MapHandler < BaseHandler
      def initialize(separator: ',', nested_separator: '_', format: nil, style: false)
        @separator = separator
        @nested_separator = nested_separator
        @format = format
        @style = style
      end

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(*values)
        result = {}

        each_value(values.flatten) do |key, value|
          if FalseClass === value
            result.delete(format(key))
          else
            result[format(key)] = value
          end
        end

        return JSON.generate(result) unless @style

        result.each_with_object(':').map(&:join).join(@separator)
      end

      def each_value(input, prefix: '', &block)
        case input
        when Hash
          input.each { |key, value| each_value(value, prefix: prefix + key.to_s + @nested_separator, &block) }
        when TrueClass, FalseClass
          block.call(input, prefix.chomp(@nested_separator)) unless prefix.empty?
        else
          split_string(input).each { |key, value| block.call(key.prepend(prefix), value) }
        end
      end

      def split_string(value, &block)
        return JSON.parse(value).each_pair(&block) unless @style

        Crass.parse_properties(value, preserve_comments: false).each do |node|
          block.call(node[:name], node[:value]) if node[:node] == :property
        end
      end
    end
  end
end
