# frozen_string_literal: true

module Torque
  module Admin
    module PaginationController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, state, paginate: default_pagination_settings, **)
          scope = apply_collection_pagination(scope, state, paginate) if paginate
          defined?(super) ? super(scope, state, **) : scope
        end

        def apply_collection_pagination(scope, state, settings)
          scope
        end

        def default_pagination_settings
        end

        def current_pagination_value
        end
    end
  end
end
