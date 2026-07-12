# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Collection State
    class CollectionState
      include Enumerable

      attr_accessor :collection
      attr_reader :table

      delegate :[], :each, :size, :length, to: :@collection

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

      def provides?(key)
        @table.key?(key.to_sym)
      end

      def on_ready(&block)
        ready? ? block.call(self) : callbacks << block
        self
      end

      def respond_to_missing?(method_name, *)
        @table.key?(method_name.to_sym) || super
      end

      def method_missing(method_name, *, **, &)
        @table.key?(method_name.to_sym) ? @table[method_name.to_sym] : super
      end

      private

        def callbacks
          @callbacks ||= []
        end
    end
  end
end
