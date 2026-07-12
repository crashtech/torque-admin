# frozen_string_literal: true

module Torque
  module Admin
    module FormController
      extend ActiveSupport::Concern

      included do
        helper_method :form_record
      end

      # TODO: Here we can setup a form element for a given action. This will simple coordinate prepare the underlying
      # action to have a properly loaded form element and allow an inline setup of a Torque Form with some sparkling
      # additions from the Admin Resource information

      protected

        ## External methods

        def form_record
          ivar = try(:member_ivar_name) || :"@#{admin_resource.singular_key}"
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, initialize_form_record)
        end

        def initialize_form_record
          processing_member_action? ? find_member! : build_new_record
        end

        # Internal methods

        def initialize_form(name = nil, **)
          # fetch_element(name || :"#{action_name}_form", values: params, **)
        end

        def build_new_record(scope: nil, using: nil, attributes: nil)
          using ||= route_annotation(:nesting).nil? ? :new : :build
          (scope || scoped_resource).public_send(using, attributes)
        end
    end
  end
end
