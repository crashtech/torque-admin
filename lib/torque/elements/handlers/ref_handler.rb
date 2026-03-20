# frozen_string_literal: true

require 'active_support/inflector/transliterate'
require 'active_support/inflector/methods'

module Torque
  module Elements
    # = Torque Elements \Ref Handler
    class RefHandler < BaseHandler
      include ActiveSupport::Inflector

      FORMATS = %i[underscore dash camel_case lower_camel_case].freeze

      def initialize(format: :underscore, strip_separators: true)
        @strip_separators = strip_separators
        @format = format
      end

      def collapse(value)
        value = format(transliterate(value.to_s))
        return value unless @strip_separators

        value.tr('/', '_').gsub(/::/, '')
      end

      def format(value)
        case @format
        when :underscore then underscore(value)
        when :dash then dasherize(underscore(value))
        when :camel_case then camelize(value)
        when :lower_camel_case then camelize(value, false)
        end
      end
    end
  end
end
