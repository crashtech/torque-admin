# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Name Handler
    class NameHandler < RefHandler
      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(value)
        value.flatten.each_with_object(+'') do |input, result|
          result << (result.empty? ? super(input) : "[#{super(input)}]")
        end
      end
    end
  end
end
