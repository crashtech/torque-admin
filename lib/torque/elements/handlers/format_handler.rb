# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Format Handler
    class FormatHandler < RefHandler
      def initialize(format, include_first: true)
        @format = format.to_s
        @include_first = include_first
      end

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(value)
        value.flatten.each_with_object(+'') do |input, result|
          next if (input = deref(input)).nil?

          input = format(@format, input) if !result.empty? || @include_first
          result << input
        end
      end
    end
  end
end
