# frozen_string_literal: true

module Torque
  module Admin
    module PaginationController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, paginate: default_pagination_settings, **)
          scope = paginate_collection(scope, paginate) if paginate
          super(scope, **)
        end

        def paginate_collection(scope, settings)
        end

        def default_pagination_settings
        end

        def current_pagination_value
        end
    end
  end
end
