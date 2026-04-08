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
        item(identifier, **options, &block)
      end

      def item(identifier, path_or_label = nil, path = nil, **options, &block)
        sub_opts = options.delete(:submenu)
        wrap_block = -> { submenu("#{identifier}-submenu", **sub_opts, skip_depth: true, &block) } if block_given?

        reindex(identifier, node_id("#{identifier}-container")) if key?(identifier) && !key?("#{identifier}-container")

        if (path ||= path_or_label).nil?
          add_node(identifier, :header, label: identifier, **options, &wrap_block)
        else
          add_node(identifier, :item, label: identifier, href: path, **options, &wrap_block)
        end
      end

      def submenu(identifier, **options, &block)
        add_node(identifier, :submenu, **options, &block)
      end

      ## Renderer

      # def sanitize_options(id, type, options)
      #   options[:id] = id == 'root' ? @name : id
      #   super
      # end

      def text_for_fallback(value, *)
        value.is_a?(String) ? value : value.to_s.underscore.titleize
      end

      ## Others

      def items
        nodes_of_type(:item)
      end

    end
  end
end
