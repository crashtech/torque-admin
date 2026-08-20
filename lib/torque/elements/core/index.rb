# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Index
      #
      # Each element hosts its own lazy index of identified nodes, obfuscated from parents.
      # Nested elements are entries in their parent's index; their internals are not.
      # Reaching in uses varargs: +fetch(:address, :street)+.
      module Index
        extend ActiveSupport::Concern

        def index
          return @index if defined?(@index)

          @index = {}
          load_config!
          @index
        end

        def [](key)
          key == :root ? self : index[node_id(key)]
        end

        def fetch(key, *rest)
          node = key == :root ? self : index.fetch(node_id(key)) do
            raise KeyError, "Key not found: #{key.inspect}"
          end

          rest.empty? ? node : node.fetch(*rest)
        end

        def key?(key)
          key == :root || index.key?(node_id(key))
        end

        alias has? key?

        def size
          index.size
        end

        protected

          def node_id(value)
            Elements.node_id(value)
          end

          def index_node(node)
            raise ArgumentError, +'Node must have an id' unless node.id
            raise ArgumentError, "Node with id '#{node.id}' already exists" if index.key?(node.id)

            index[node.id] = node
          end

          def unindex_node(node)
            index.delete(node.id) if node.respond_to?(:id)
          end

          def reindex(node, as)
            unindex_node(node)
            index[node.instance_variable_set(:@id, node_id(as))] = node
          end

          def ref_to_node(value)
            return self if value == :root
            return value if value.is_a?(BasicNode)
            return @current || self if value.eql?(true)

            fetch(value)
          end

          def nodes_of_type(type)
            index.each_value.select { |node| node =~ type }
          end
      end
    end
  end
end
