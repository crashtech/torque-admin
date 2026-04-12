# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Ref Handler
    class RefHandler < BaseHandler
      def initialize(format: :underscore, separator: '_')
        @separator = separator
        @format = format
      end

      def collapse(value)
        return if value.nil?

        value = format(deref(value))
        return value unless @separator

        value.tr('/', @separator).tr(':', '')
      end

      def deref(value)
        (value.is_a?(Symbol) && Context.refs[value]) || value.to_s
      end
    end
  end
end
