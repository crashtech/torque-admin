# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Link Node
    class LinkNode < Node
      def active?
        return @active if defined?(@active)
        return unless (path = href).present?
        return unless defined?(@element) && (setting = @element.try(:current_link_setting))

        helper = TrueClass === setting ? :current_page? : setting
        helper = Context.view_context.method(helper) unless helper.respond_to?(:call)
        @active = helper.call(path)
      end

      alias current? active?

      def href
        current = options[:href]
        return current if current.is_a?(String)

        options[:href] = Context.view_context.url_for(current) if current
      end

      def sanitize_link_options
        href
        options[:active] = true if active?
      end

      protected

        def sanitized_options!
          super
          sanitize_link_options
        end
    end
  end
end


      # def sanitize_node_item_options(node)
      #   icons_helper&.call(node)
      # end
