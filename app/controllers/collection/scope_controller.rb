# frozen_string_literal: true

module Torque
  module Admin
    module ScopeController
      extend ActiveSupport::Concern

      protected

        def load_collection(s, state, scope: default_scope_settings, **)
          s = scope_collection(s, state, scope) if scope
          super(s, state, **)
        end

        def scope_collection(scope, state, settings)
          scope
        end

        def default_scope_settings
        end

        def current_scope_value
        end
    end
  end
end
