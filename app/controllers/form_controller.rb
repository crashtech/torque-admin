# frozen_string_literal: true

module Torque
  module Admin
    module FormController
      extend ActiveSupport::Concern

      included do
        helper_method(:form_record)
      end

      protected

        ## External methods

        def form_record
          return build_record unless respond_to?(:resource)

          param.key?(route_annotation(:resource).param) ? resource : build_record
        end

        def build_record
          ivar = :"@#{route_annotation(:resource).singular}"
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, initialize_record)
        end

        # Internal methods

        def initialize_record
        end
    end
  end
end
