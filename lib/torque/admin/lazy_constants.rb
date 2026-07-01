# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Lazy Constants
    module LazyConstants
      extend ActiveSupport::Concern

      def const_missing(name)
        return super unless instance_variable_defined?(:@lazy_constants)
        return super if (handler = @lazy_constants[name]).nil?

        const_set(name, handler.call(self))
      end

      protected

        def lazy_constant(*names, &block)
          (@lazy_constants ||= {}).merge!(names.index_with { block })
        end

        def clear_lazy_constants
          (constants & @lazy_constants.keys).each { |name| remove_const(name) }
        end
    end
  end
end
