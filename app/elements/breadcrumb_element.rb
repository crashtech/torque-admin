# frozen_string_literal: true

module Torque
  module Admin
    # = Torque Admin \Breadcrumb Element
    class BreadcrumbElement < BaseElement
      def type
        :breadcrumb
      end

      ## Define nodes

      def home(label = nil)
        label = nil if TrueClass === label
        item(:home, label, view_context.root_path, prepend_to: :root)
      end

      def item(identifier, href_or_label = nil, href = nil, **, &)
        href, href_or_label = href_or_label, nil if href.nil?
        add_node(identifier, :item, label: href_or_label || identifier, href:, **, &)
      end

      def pop
        remove(root.children.last)
      end

      ## Generators

      def build_simple(with_home: true, with_section: true)
        home(with_home) if with_home
        return build_dashboard(with_section) if current_dashboard?

        build_section(with_section) if with_section
      end

      def build_full_chain(with_home: true, with_section: true)
        home(with_home) if with_home
        return build_dashboard(with_section) if current_dashboard?

        build_section(with_section) if with_section
      end

      def build_full_route(with_home: true, with_section: true)
        home(with_home) if with_home
        return build_dashboard(with_section) if current_dashboard?

        build_section(with_section) if with_section
      end

      def build_section(label)
        return unless (section = view_context.route_annotation(:section))

        href = Rails.error.handle(ActionController::UrlGenerationError, severity: :info) do
          view_context.url_for(controller: "#{section}_dashboard", action: :show)
        end

        item(section, label, href)
      end

      def build_dashboard(with_section)
        controller = [*view_context.route_annotation(:section), :dashboard].join('_')
        build_section(with_section) if with_section && controller != view_context.admin_controller_name

        name = request.get_header('action_dispatch.route').name.to_sym
        item(name, nil, view_context.url_for(controller: controller, action: :show))
      end

      ## Renderer

      def sanitize_node_item_options(node)
        node[:href] = view_context.url_for(node[:href]) if node[:href]
      end

      ## Helpers

      def current_dashboard?
        view_context.route_annotation(:source) == :dashboard
      end
    end
  end
end
