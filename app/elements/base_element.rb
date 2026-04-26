# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Base Element
    class BaseElement < Elements::Base
      self.abstract_class = true

      def element_settings
        super + %i[placement]
      end
    end
  end
end
