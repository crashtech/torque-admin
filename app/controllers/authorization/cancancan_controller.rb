# frozen_string_literal: true

module Torque
  module Admin
    module CancancanController
      extend ActiveSupport::Concern

      included do
        include CanCan::ControllerAdditions

        before_action :authorize_action!, if: :authentication_protected_route?
      end

      protected

        def authorize_action!(action = action_name.to_sym, resource: authorizable_resource)
          authorize!(action, resource)
        rescue CanCan::AccessDenied => e
          raise if (fallback = fallback_authorization_action).nil? || cannot?(fallback, resource)
        end

        def scoped_resource
          super.accessible_by(current_ability, action_name.to_sym)
        end

        def nested_scope_from(...)
          super.accessible_by(current_ability, :show)
        end

        def build_new_record(**, attributes: nil)
          if (values = current_ability.attributes_for(action_name.to_sym, admin_resource_class)).present?
            attributes = attributes.nil? ? values : values.deep_merge(attributes)
          end

          super(**, attributes: attributes)
        end

    end
  end
end
