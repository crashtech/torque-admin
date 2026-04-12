# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Index
      module Index
        extend ActiveSupport::Concern

        attr_reader :index

        def initialize
          @index = { root: @root }
        end

        def [](key)
          index[node_id(key)]
        end

        def key?(key)
          index.key?(node_id(key))
        end

        alias has? key?

        def size
          index.size - 1
        end

        def clear!
          @index = nil
        end

        protected

          def node_id(value)
            return value if value == :root || (value.is_a?(String) && value.frozen?)

            value.to_s.downcase.gsub(/[_\s]/, '-').gsub(/[^-a-z0-9]/, '')
          end

          def index_node(node)
            raise ArgumentError, "Node with id '#{node.id}' already exists" if index.key?(node.id)

            index[node.id] = node
          end

          alias add_node index_node

          def remove_node(node)
            index.delete(node.id)
          end

          def reindex(node, as)
            node = self[node] unless node.is_a?(Node)

            index.delete(node.id)
            index[node.instance_variable_set(:@id, as)] = node
          end

          def nodes_of_type(type)
            index.each_value.select { |node| node =~ type }
          end
      end
    end
  end
end
