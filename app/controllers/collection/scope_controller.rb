# frozen_string_literal: true

module Torque
  module Admin
    module ScopeController
      extend ActiveSupport::Concern

      protected

        def load_collection(a_scope, scope: default_scope_settings, **)
          a_scope = scope_collection(a_scope, scope) if scope
          super(a_scope, **)
        end

        def scope_collection(scope, settings)
        end

        def default_scope_settings
        end

        def current_scope_value
        end
    end
  end
end
