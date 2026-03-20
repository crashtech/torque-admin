# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Bootstrap Helpers
      module Bootstrap
        extend HelperBuilder

        define :badge do |b|
          b.preset(:default, as: 'span', class: 'badge')
          b.preset(:pill, class: 'rounded-pill')
          b.preset(:bubble, class: 'position-absolute top-0 start-100 translate-middle')

          b.property(:color).formats(:class, 'text-bg-%s')
        end

      end
    end
  end
end
