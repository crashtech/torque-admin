# frozen_string_literal: true

require_relative 'core/definition'
require_relative 'core/index'
require_relative 'core/nodes'
require_relative 'core/rendering'

module Torque
  module Elements
    # = Torque Elements \Base
    #
    # Elements are supposed to represent a logical structure of a component. Therefore,
    # all nodes must retain that concept and avoid representing a physical structure.
    # For example, the logical representation of a table is its columns, not its rows.
    # Such representation can then be split into proper headers and other physical nodes.
    class Base

      include Core::Index
      include Core::Nodes
      include Core::Rendering

      include Core::Definition

      def inspect
        "#<#{self.class.name} #{name} nodes=#{size}>"
      end

    end
  end
end
