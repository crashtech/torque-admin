# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Value Reader
    module ValueReader
      extend ActiveSupport::Concern

      def read_value_for(source, attribute, from: nil)
        source = read_value_for(source, from) if from
        return if source.nil?

        case read_mode
        when :call then source.public_send(attribute)
        when :hash, :object then source[attribute.to_sym]
        when :json then source[attribute.to_s]
        when :dig then source.dig(attribute)
        when :any, :try
          return source.public_send(attribute) if source.respond_to?(attribute)
          return source[attribute.to_sym] if source.try?(:key?, attribute.to_sym)
          source[attribute.to_s] if source.try?(:key?, attribute.to_s)
        else
          raise ArgumentError, "Unknown read mode: #{read_mode.inspect}"
        end
      end

      def read_mode
        return settings(:read_mode) if settings?(:read_mode)

        change_setting(:read_mode, default_read_mode)
      end

      protected

        def default_read_mode
          :call
        end
    end
  end
end
