# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Menu Element
    class MenuElement < Elements::Base
      def initialize(*args, sort: nil, icons: nil, **options, &block)
        @sort = sort
        @icons = icons
        super(*args, **options, &block)
      end

      def validate!
        raise ArgumentError, "Invalid sort option: #{@sort}" if @sort && !%i[root children all].include?(@sort)
        raise ArgumentError, "Invalid icons option: #{@icons}" if @icons && !@icons.is_a?(Hash)
        super
      end

      ## Define nodes

      def item(identifier, href_or_label = nil, href = nil, **options, &block)
        reindex(identifier, node_id("#{identifier}-container")) if key?(identifier) && !key?("#{identifier}-container")

        options[:icon] ||= @icons[identifier] if @icons

        href, href_or_label = href_or_label, nil if href.nil?
        add_node(identifier, :item, label: href_or_label || identifier, href: href, **options, &block)
      end

      ## Renderer

      def text_for_fallback(value, *)
        value.is_a?(String) ? value : value.to_s.underscore.titleize
      end

      ## Overrides

      def define(*)
        @sort ? super.tap { apply_sorting!(@sort) } : super
      end

      ## Others

      def links
        index.each_value.select { |node| node.options[:href] }
      end

      def apply_sorting!(mode = @sort)
        sortable_lists(mode).each { |list| list.sort_by!(&method(:label_for)) }
      end

      def label_for(node)
        resolve_text_for(node, :label)
      end

      protected

        # TODO: Make this generic to sort by depth number filtered by types
        def sortable_lists(mode)
          return [nodes] if mode == :root

          queue = [*nodes]
          result = mode == :children ? [] : [nodes]

          while queue.any?
            current = queue.shift
            queue += current.children if current.branch?
            result << current.children
          end

          result
        end

    end
  end
end
