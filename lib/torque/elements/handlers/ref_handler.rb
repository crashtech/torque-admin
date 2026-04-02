# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Ref Handler
    class RefHandler < BaseHandler
      def initialize(format: :underscore, separator: '_')
        @separator = separator
        @format = format
        super()
      end

      def collapse(value)
        value = format(transliterate(value.to_s))
        return value unless @separator

        value.tr('/', @separator).tr(':', '')
      end
    end
  end
end
