# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Menu Element
    class MenuElement < Elements::Base
      attr_accessor :sort, :icons, :detect_current
      attr_writer :icon_position

      def initialize(*, sort: nil, icons: nil, detect_current: nil, **, &)
        @sort = sort
        @icons = icons
        @detect_current = detect_current

        super(*, **, &)
      end

      def clear!
        @sort = @icons = @detect_current = @icons_helper = @detect_current_helper = nil
        super
      end

      def type
        :menu
      end

      ## Define nodes

      def item(identifier, href_or_label = nil, href = nil, **, &)
        current = self[identifier]
        reindex(current, node_id("#{identifier}-container")) if current && !key?("#{identifier}-container")

        href, href_or_label = href_or_label, nil if href.nil?
        add_node(identifier, :item, label: href_or_label || identifier, href: href, **, &)
      end

      def divider
        add_node(nil, :divider)
      end

      ## Renderer

      def sanitize_node_options(node)
        return super unless node =~ :item

        node[:href] = @context.url_for(node[:href]) if node[:href]
        change_current_indicator(node) if @detect_current
        icons_helper.call(node) if @icons
        super
      end

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

      def change_current_indicator(node)
        node[:active] = true if current_active?(node)
      end

      def current_active?(node)
        node[:href].present? && detect_current_helper.call(node[:href])
      end

      def detect_current_helper
        @detect_current_helper ||= @context.method(TrueClass === @detect_current ? :current_page? : @detect_current)
      end

      def icons_helper
        @icons_helper ||=
          if @icons.is_a?(Hash)
            index = @icons.transform_keys { |key| node_id(key) }
            ->(node) { node[:icon] = index[node.id] }
          else
            helper = TrueClass === @icons ? :icon : @icons
            helper = @context.respond_to?(helper) ? @context.method(helper) : @context.ui.method(helper)
            ->(node) { node.append(icon_position => helper.call(node.id)) }
          end
      end

      def icon_position
        @icon_position ||= :after
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
