# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Content Handler
    class ContentHandler < BaseHandler
      PARTS = %i[prepend before content after append].freeze

      def combine(current, value)
        list_combine(current, value)
      end

      def collapse(value)
        result = PARTS.product([nil]).to_h
        each_value(value) do |part, content|
          (result[part] ||= []) << content
        end

        result = result.compact.transform_values(&:flatten)
        result[:prepend]&.reverse!
        result
      end

      def each_value(input)
        input.flatten.each do |value|
          value = { content: value } unless value.is_a?(Hash)
          PARTS.each { |part| value[part].presence&.then { |content| yield(part, content) } }
        end
      end
    end
  end
end
