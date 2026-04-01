# frozen_string_literal: true

require 'active_support/inflector/transliterate'
require 'active_support/inflector/methods'

module Torque
  module Elements
    # = Torque Elements \Ref Handler
    class RefHandler < BaseHandler
      def initialize(format: :underscore, strip_separators: true)
        @strip_separators = strip_separators
        @format = format
      end

      def collapse(value)
        value = format(transliterate(value.to_s))
        return value unless @strip_separators

        value.tr('/', '_').gsub(/::/, '')
      end
    end
  end
end
