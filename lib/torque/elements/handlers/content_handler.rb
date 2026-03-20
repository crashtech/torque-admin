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
        result = value.flatten.each_with_object(PARTS.product([nil]).to_h) do |input, result|
          next (result[:content] ||= []) << input unless input.is_a?(Hash)

          PARTS.each do |part|
            next if (piece = input[part]).blank?
            (result[part] ||= []) << piece
          end
        end

        result = result.compact.transform_values(&:flatten)
        result[:prepend]&.reverse!
        result
      end
    end
  end
end
