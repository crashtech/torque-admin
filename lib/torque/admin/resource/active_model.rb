# frozen_string_literal: true

module Torque
  module Admin
    class Resource
      # = Torque Admin \Resource Active Model
      module ActiveModel
        def singular_key
          resource_class.try(:model_name)&.singular || super
        end

        def singular_title
          resource_class.try(:model_name)&.human || super
        end

        def plural_key
          resource_class.try(:model_name)&.plural || super
        end

        def plural_title
          resource_class.try(:model_name)&.human(count: 2) || super
        end
      end
    end
  end
end
