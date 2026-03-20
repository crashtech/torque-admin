# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \MaterialUI Helpers
      module MaterialUI

        def badge(content, &block)
          content = capture(&block) if block_given?
          view_context.tag('md-assist-chip', label: content)
        end

        alias chip badge

      end
    end
  end
end
