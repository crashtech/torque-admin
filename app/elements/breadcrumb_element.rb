# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Breadcrumb Element
    #
    # The name is in singular form mostly due to MDN and W3C using "breadcrumb" instead of "breadcrumbs"
    class BreadcrumbElement < BaseElement
      include ItemsFromAction

      attr_accessor :divider_content

      alias label_for action_label_for
      alias import_from_current_action import_items_from_current_action

      node :item, as: :link
      node :divider, as: :basic

      setting :auto_dividers

      ## Define nodes

      def home(label = nil)
        item(:home, (label unless TrueClass === label), view_context.url_for(:root), prepend_to: :root)
      end

      def section(label, href_or_name = nil)
        return item(:section, label, href_or_name) if href_or_name.is_a?(String)

        section = href_or_name.is_a?(Symbol) ? href_or_name : view_context.route_annotation(:section)
        item(:section, label, { controller: "#{section}_dashboard", action: :index })
      end

      def item(identifier, href_or_label = nil, href = nil, **options, &)
        divider if children.any? && auto_dividers?

        href, href_or_label = href_or_label, nil if href.nil?
        href_or_label = label_for(href[:action], controller: href[:controller]) if href_or_label == true

        options[:href] ||= href
        options[:label] ||= href_or_label || identifier

        super(identifier, **options, &)
      end

      alias import_item item

      def divider(content = nil)
        super(prepend: content || divider_content || '/')
      end

      def pop
        remove(children.last)
      end

      ## Others

      def auto_dividers!
        change_setting(:auto_dividers, true)
      end

      def auto_dividers?
        settings(:auto_dividers, view_context.try(:ui).try(:breadcrumb_with_dividers))
      end
    end
  end
end
