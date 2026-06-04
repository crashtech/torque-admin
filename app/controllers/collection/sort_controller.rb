# frozen_string_literal: true

module Torque
  module Admin
    module SortController
      extend ActiveSupport::Concern

      protected

        def load_collection(s, state, sort: default_sort_settings, **)
          sort ? sort_collection(s, state, paginate) : s
        end

        def sort_collection(scope, state, settings)
          scope
        end

        def default_sort_settings
        end

        def current_sort_value
        end
    end
  end
end
