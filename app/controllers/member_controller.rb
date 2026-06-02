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

          instance_variable_set(ivar, find_member!)
        end

        alias member resource

        def find_member!(id = params[RESOURCE_PARAM], scope: nil, by: scope.model.primary_key)
          (scope || scoped_resource).find_sole_by(by => id)
        end

        # Internal methods

        def member_ivar_name
          :"@#{RESOURCE.singular}"
        end
    end
  end
end
