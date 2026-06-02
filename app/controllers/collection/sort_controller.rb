# frozen_string_literal: true

module Torque
  module Admin
    module SortController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, sort: default_sort_settings, **)
          scope = sort_collection(scope, sort) if sort
          super(scope, **)
        end

        def sort_collection(scope, settings)
        end

        def default_sort_settings
        end

        def current_sort_value
        end
    end
  end
end
