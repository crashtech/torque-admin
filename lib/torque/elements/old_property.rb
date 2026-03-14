# frozen_string_literal: true

module Torque
  module Elements
    class Property
      def initialize(name)
        @name = name.to_s.tr('-', '_').to_sym
      end
    end
  end
end
