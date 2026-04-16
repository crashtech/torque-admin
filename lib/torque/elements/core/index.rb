# frozen_string_literal: true

module Torque
  module Elements
    module Core
      # = Torque Elements \Core Index
      module Index
        extend ActiveSupport::Concern

        def clear!
          @index = nil
        end

        def index
          return @index if defined?(@index)

          @index = { root: @root }
          load_config!
          @index
        end

        def [](key)
          index[node_id(key)]
        end

        def fetch(key)
          index.fetch(node_id(key)) { raise KeyError, "Key not found: #{key.inspect}" }
        end

        def key?(key)
          index.key?(node_id(key))
        end

        alias has? key?

        def size
          index.size - 1
        end

        protected

          def node_id(value)
            return if value.nil?
            return value if value == :root || (value.is_a?(String) && value.frozen?)

            value.to_s.downcase.gsub(/[_\s]/, '-').gsub(/[^-a-z0-9]/, '')
          end

          def index_node(node)
            raise ArgumentError, +'Node must have an id' unless node.id
            raise ArgumentError, "Node with id '#{node.id}' already exists" if index.key?(node.id)

            index[node.id] = node
          end

          def unindex_node(node)
            index.delete(node.id)
          end

          def reindex(node, as)
            unindex_node(node)
            index[node.instance_variable_set(:@id, as)] = node
          end

          def nodes_of_type(type)
            index.each_value.select { |node| node =~ type }
          end
      end
    end
  end
end
