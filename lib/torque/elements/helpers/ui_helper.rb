# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \UI Helpers
      module UiHelper
        def ui
          ui_builder
        end

        private

          def ui_builder
            @ui_builder ||= UiBuilder.new(self, framework: ui_framework)
          end
      end
    end
  end
end
