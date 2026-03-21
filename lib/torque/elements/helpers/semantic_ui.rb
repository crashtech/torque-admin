# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \SemanticUI Helpers
      module SemanticUI
        extend HelperConstructor

        ICON = +'icon %s'
        SIZES = %w[mini tiny small default large big huge massive].each_with_index.with_object({}) do |(name, idx), result|
          result[idx + 1] = result[name] = name == 'default' ? '' : name
        end.with_indifferent_access.freeze

        shared(:icon) { |b| b.calls(:icon).adds_to_content(:before) }
        shared(:size) { |b| b.maps_using(:SIZES).assigns(:class) }
        shared(:color) { |b| b.assigns(:class) }

        load_definitions './semantic_ui/elements'


      end
    end
  end
end
