# frozen_string_literal: true

module Torque
  module Admin
    module FilterController
      extend ActiveSupport::Concern

      protected

        def load_collection(s, state, filter: default_filter_settings, **)
          s = filter_collection(s, state, filter) if filter
          super(s, state, **)
        end

        def filter_collection(scope, state, settings)
          scope
        end

        def default_filter_settings
        end

        def current_filter_value
        end
    end
  end
end
