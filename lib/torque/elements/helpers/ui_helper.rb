# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \UI Helpers
      module UiHelper
        attr_reader :current_element

        def ui
          ui_builder
        end

        private

          def ui_builder
            @ui_builder ||= UiBuilder.new(self)
          end
      end
    end
  end
end
