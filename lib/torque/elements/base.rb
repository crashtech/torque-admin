# frozen_string_literal: true

require_relative 'core/node'

require_relative 'core/definition'
require_relative 'core/index'
require_relative 'core/nodes'
require_relative 'core/renderer'

module Torque
  module Elements
    # = Torque Elements \Base
    class Base

      include Core::Index
      include Core::Nodes
      include Core::Renderer

      include Core::Definition

      def inspect
        "#<#{self.class.name} nodes=#{@index&.size || 0}>"
      end

    end
  end
end
