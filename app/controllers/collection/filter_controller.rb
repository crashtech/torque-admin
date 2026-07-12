# frozen_string_literal: true

module Torque
  module Admin
    module FilterController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, state, filter: default_filter_settings, **)
          scope = apply_collection_filter(scope, state, filter) if filter
          defined?(super) ? super(scope, state, **) : scope
        end

        def apply_collection_filter(scope, state, settings)
          scope
        end

        def default_filter_settings
        end

        def current_filter_value
        end
    end
  end
end
