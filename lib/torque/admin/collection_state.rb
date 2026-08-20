# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Collection State
    class CollectionState
      include Enumerable

      attr_accessor :collection
      attr_reader :table

      delegate :[], :each, :size, :length, :to_a, :to_enum, to: :@collection

      def initialize
        @table = {}
      end

      def ready!(collection)
        @collection = collection
        callbacks.each { |callback| callback.call(self) }

        @table.freeze
        self
      end

      def ready?
        !!defined?(@collection)
      end

      def provide(key, value)
        raise +'State cannot be modified after it is ready' if ready?
        raise "Key #{key} is already provided" if @table.key?(key.to_sym)

        @table[key.to_sym] = value.freeze
        self
      end

      def fetch(key, from:)
        @table[from.to_sym]&.[](key.to_sym)
      end

      def provides?(key)
        @table.key?(key.to_sym)
      end

      def on_ready(&block)
        ready? ? block.call(self) : callbacks << block
        self
      end

      def aggregate(*requests)
        requests = requests.map { |operation, attribute| [operation.to_sym, attribute.to_sym] }
        missing = requests - aggregates.keys
        aggregates.merge!(requests_to_aggregates(missing)) if missing.any?
        aggregates.values_at(*requests)
      end

      def relation?
        @collection.is_a?(ActiveRecord::Relation)
      end

      def respond_to_missing?(method_name, *)
        @table.key?(method_name) || super
      end

      def method_missing(method_name, *, **, &)
        @table.key?(method_name) ? @table[method_name] : super
      end

      private

        def callbacks
          @callbacks ||= []
        end

        def aggregates
          @aggregates ||= {}
        end

        def requests_to_aggregates(requests)
          raise ArgumentError, +'Aggregates require a relation' unless relation?

          table = @collection.klass.arel_table
          nodes = requests.map { |operation, attribute| table[attribute].public_send(operation) }
          values = @collection.unscope(:limit, :offset, :order).pluck(*nodes).first
          requests.zip(Array.wrap(values)).to_h
        end
    end
  end
end
