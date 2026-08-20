# frozen_string_literal: true

module Torque
  module Admin
    module MemberController
      extend ActiveSupport::Concern

      included do
        helper_method :member, :resource
      end

      protected

        ## External methods

        def member
          ivar = member_ivar_name
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, find_member!)
        end

        alias_method :resource, :member
        alias_method :load_resource, :member

        def find_member!(id = params[self.class.primary_param], scope: nil, by: nil)
          scope = scoped_resource if scope.nil?
          scope.find_sole_by((by || self.class.identified_by || scope.model.primary_key) => id)
        end

        # Internal methods

        def member_ivar_name
          :"@#{admin_resource.singular_key}"
        end
    end
  end
end
