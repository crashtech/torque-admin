# frozen_string_literal: true

module Torque
  module Admin
    module FilterController
      extend ActiveSupport::Concern

      protected

        def load_collection(scope, filter: default_filter_settings, **)
          scope = filter_collection(scope, filter) if filter
          super(scope, **)
        end

        def filter_collection(scope, settings)
        end

        def default_filter_settings
        end

        def current_filter_value
        end
    end
  end
end
