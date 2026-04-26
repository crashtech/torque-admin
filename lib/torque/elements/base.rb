# frozen_string_literal: true

require_relative 'core/definition'
require_relative 'core/helpers'
require_relative 'core/index'
require_relative 'core/nodes'
require_relative 'core/render'

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
      include Core::Render

      include Core::Helpers
      include Core::Definition

      class_attribute :abstract_class, instance_accessor: false, instance_predicate: false
      self.abstract_class = true

      class << self
        alias abstract_class? abstract_class

        def inherited(klass)
          super
          klass.abstract_class = false
        end
      end

      def inspect
        "#<#{self.class.name} name=#{name.inspect} type=#{type.inspect} id=#{id.inspect} nodes=#{size}>"
      end

    end
  end
end
