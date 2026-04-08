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

        def key?(key)
          index.key?(node_id(key))
        end

        protected

          def node_id(value)
            value.to_s.downcase.gsub(/[_\s]/, '-').gsub(/[^-a-z0-9]/, '')
          end

          def index_node(node)
            raise ArgumentError, "Node with id '#{node.id}' already exists" if index.key?(node.id)

            index[node.id] = node
          end

          alias add_node index_node

          def reindex(node, as)
            node = self[node] unless node.is_a?(Core::Node)

            index.delete(node.id)
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
