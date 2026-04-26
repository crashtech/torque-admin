# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Base Handler
    class BaseHandler
      LOWER_CAMEL_CASE = ->(value) { ActiveSupport::Inflector.camelize(value, false) }

      delegate :view_context, to: '::Torque::Elements::Context'

      def combine(_, value)
        value
      end

      def collapse(value)
        value
      end

      protected

        def list_combine(current, value)
          current.nil? ? [value] : current << value
        end

        def format(value)
          @format ? formatter.call(value) : value
        end

      private

        def formatter
          @formatter ||= @format.respond_to?(:call) ? @format : begin
            case @format
            when :lower_camelize, :lower_camel_case then LOWER_CAMEL_CASE
            when :dash then ActiveSupport::Inflector.method(:dasherize)
            when :camel_case then ActiveSupport::Inflector.method(:camelize)
            else ActiveSupport::Inflector.method(@format)
            end
          end
        end
    end
  end
end
