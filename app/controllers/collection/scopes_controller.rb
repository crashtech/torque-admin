# frozen_string_literal: true

module Torque
  module Admin
    module ScopesController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, state, scopes: default_scopes_settings, **)
          scope = apply_collection_scopes(scope, state, scopes) if scopes
          defined?(super) ? super(scope, state, **) : scope
        end

        def apply_collection_scopes(scope, state, settings)
          scope
        end

        def default_scopes_settings
        end

        def current_scopes_value
        end
    end
  end
end
