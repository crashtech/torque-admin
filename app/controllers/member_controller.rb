# frozen_string_literal: true

module Torque
  module Admin
    module MemberController
      extend ActiveSupport::Concern

      included do
        helper_method(:resource, :member)
      end

      protected

        ## External methods

        def resource
          ivar = member_ivar_name
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, initialize_resource)
        end

        alias member resource

        def initialize_resource(id = nil, by: route_annotation(:resource).param)
          id = params[by] if id.nil?
        end

        alias initialize_member initialize_resource

        # Internal methods

        def member_ivar_name
          :"@#{route_annotation(:resource).singular}"
        end
    end
  end
end
