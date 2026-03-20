# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Bulma Helpers
      module Bulma

        def badge(content, &block)
          tag_builder.span(content, class: 'tag', &block)
        end

        alias tag badge

      end
    end
  end
end
