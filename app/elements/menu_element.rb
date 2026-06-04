# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Menu Element
    class MenuElement < BaseElement
      def clear!
        @icons_helper = @detect_current_helper = nil
        super
      end

      def type
        :menu
      end

      def element_settings
        super + %i[sort icons detect_current icon_position]
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

        node[:href] = view_context.url_for(node[:href]) if node[:href]
        change_current_indicator(node) if settings[:detect_current]
        icons_helper.call(node) if settings[:icons]
        super
      end

      def text_for_fallback(value, *)
        value.is_a?(String) ? value : value.to_s.underscore.titleize
      end

      ## Overrides

      def load_config!(*)
        settings[:sort] ? super.tap { apply_sorting! } : super
      end

      ## Others

      def links
        index.each_value.select { |node| node.options[:href] }
      end

      def apply_sorting!(mode = settings[:sort])
        super(mode) { |node| label_for(node) }
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
        @detect_current_helper ||= begin
          method = TrueClass === settings[:detect_current] ? :current_page? : settings[:detect_current]
          method.respond_to?(:call) ? method : view_context.method(method)
        end
      end

      def icons_helper
        @icons_helper ||=
          if settings[:icons].is_a?(Hash)
            index = settings[:icons].transform_keys { |key| node_id(key) }
            ->(node) { node[:icon] = index[node.id] }
          else
            helper = TrueClass === settings[:icons] ? :icon : settings[:icons]
            helper = view_context.respond_to?(helper) ? view_context.method(helper) : view_context.ui.method(helper)
            position = settings.fetch(:icon_position, :after)
            ->(node) { node.append(position => helper.call(node.id)) }
          end
      end

      protected

        # TODO: Make this generic to sort by depth number filtered by types
        def sortable_lists(mode)
          return [nodes] if mode == :root

          queue = [*nodes]
          result = mode == :children ? [] : [nodes]

          while queue.any?
            if (current = queue.shift).branch?
              queue += current.children
              result << current.children
            end
          end

          result
        end

    end
  end
end
