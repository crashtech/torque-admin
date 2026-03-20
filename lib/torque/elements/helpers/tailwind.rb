# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Tailwind Helpers
      module Tailwind

        def badge(content, &block)
          tag_builder.span(content, class: "inline-flex items-center rounded-full bg-gray-100 px-2 py-1 text-xs font-medium text-gray-800", &block)
        end

      end
    end
  end
end
