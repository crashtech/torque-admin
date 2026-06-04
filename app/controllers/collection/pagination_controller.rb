# frozen_string_literal: true

module Torque
  module Admin
    module PaginationController
      extend ActiveSupport::Concern

      protected

        def load_collection(s, state, paginate: default_pagination_settings, **)
          s = paginate_collection(s, state, paginate) if paginate
          super(s, state, **)
        end

        def paginate_collection(scope, state, settings)
          scope
        end

        def default_pagination_settings
        end

        def current_pagination_value
        end
    end
  end
end
