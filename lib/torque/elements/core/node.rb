# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Node
      class Node
        attr_reader :id, :type, :parent, :options

        def initialize(id, type, options = nil, parent:)
          @id = id
          @type = type.to_sym
          @parent = parent

          @options = options
        end

        def memo
          @memo ||= {}
        end

        def children
          @children ||= []
        end

        def leaf?
          @children.nil?
        end

        def of_type?(value)
          type == value.to_sym
        end

        def inspect
          "#<#{self.class.name} id=#{id.inspect} type=#{type.inspect}>"
        end
      end
    end
  end
end
