# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Index
      module Index
        extend ActiveSupport::Concern

        def [](key)
          index[node_id(key)]
        end

        protected

          def add_node(node)
            reindex(index[node.id]) if index.key?(node.id)
            index[node.id] = node
          end

          def reindex(node, as = "#{node.id}-container")
            index[node.instance_variable_set(:@id, as)] = node
          end

        private

          def index
            @index ||= {}
          end
      end
    end
  end
end
