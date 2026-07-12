# frozen_string_literal: true

module Torque
  module Admin
    module SortController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, state, sort: default_sort_settings, **)
          scope = apply_collection_sort(scope, state, sort) if sort
          defined?(super) ? super(scope, state, **) : scope
        end

        def apply_collection_sort(scope, state, settings)
          scope
        end

        def default_sort_settings
        end

        def current_sort_value
        end
    end
  end
end
