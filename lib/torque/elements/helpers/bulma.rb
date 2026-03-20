# frozen_string_literal: true

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Bulma Helpers
      module Bulma
        extend HelperBuilder

        ICON = 'fas fa-%s'
        SIZES = %w[small default normal medium large].each_with_index.with_object({}) do |(name, idx), result|
          result[idx + 1] = result[name] = name == 'default' ? '' : "is-#{name}"
        end.with_indifferent_access.freeze

        load_definitions './bulma/elements'

      end
    end
  end
end
