# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Base Handler
    class BaseHandler
      def combine(_, value)
        value
      end

      def collapse(value)
        value
      end

      protected

        def list_combine(current, value)
          value = [value] if value.is_a?(Hash)
          result = [*current, *value]
          result
        end
    end
  end
end
