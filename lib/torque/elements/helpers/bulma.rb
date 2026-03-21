# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Bulma Helpers
      module Bulma
        extend HelperConstructor

        ICON = +'fas fa-%s'
        SIZES = %w[small default normal medium large].each_with_index.with_object({}) do |(name, idx), result|
          result[idx + 1] = result[name] = name == 'default' ? '' : "is-#{name}"
        end.with_indifferent_access.freeze

        shared(:icon) { |b| b.calls(:icon).adds_to_content(:before).wrap_content(:span) }
        shared(:size) { |b| b.maps_using(:SIZES).assigns(:class) }
        shared(:color) { |b| b.formats(:class, 'is-%s') }

        load_definitions './bulma/elements'

      end
    end
  end
end
