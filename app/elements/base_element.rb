# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Base Element
    class BaseElement < Elements::Base
      self.abstract_class = true

      # TODO: This is just a placeholder right now
      def element_settings
        super + %i[placement]
      end
    end
  end
end
