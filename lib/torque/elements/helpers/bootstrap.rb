# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Bootstrap Helpers
      module Bootstrap
        extend HelperConstructor

        ICON = +'fas fa-%s'
        SIZES = { sm: 'sm', default: '', lg: 'lg' }.with_indifferent_access.freeze

        shared(:icon) { |b| b.calls(:icon).adds_to_content(:before) }
        shared(:size) { |b| b.maps_using(:SIZES).assigns(:class) }
        shared(:color) { |b| b.assigns(:class) }

        load_definitions './bootstrap/elements'

      end
    end
  end
end
