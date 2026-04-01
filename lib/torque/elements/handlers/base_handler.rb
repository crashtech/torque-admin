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

        def format(value)
          @format ? formatter.call(value) : value
        end

      private

        def formatter
          @formatter ||= @format.respond_to?(:call) ? @format : begin
            case @format
            when :lower_camelize, :lower_camel_case then
              proc { |value| ActiveSupport::Inflector.camelize(value, false) }
            when :dash then ActiveSupport::Inflector.method(:parameterize)
            when :camel_case then ActiveSupport::Inflector.method(:camelize)
            else ActiveSupport::Inflector.method(@format)
            end
          end
        end
    end
  end
end
