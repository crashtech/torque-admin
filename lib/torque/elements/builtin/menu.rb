# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Menu
    class Menu < Base

      def initialize(*args, sort: nil, **options, &block)
        @sort = sort
        super(*args, **options, &block)
      end

      ## Define elements

      def header(identifier, **options, &block)
        item(identifier, nil, **options, &block)
      end

      def item(identifier, path = nil, **options, &block)
        if path.nil?
          add_node(identifier, :header, label: identifier, **options, &block)
        else
          add_node(identifier, :item, label: identifier, href: path, **options, &block)
        end
      end

      ## Renderer

      def text_for_fallback(value)
        value.to_s.underscore.titleize
      end

      ## Others

      def items
        nodes_of_type(:item)
      end

    end
  end
end
