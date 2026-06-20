# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Link Node
    class LinkNode < Node
      self.settings += %i[remove_if_invalid]

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
        return if (current = options[:href]).nil?
        return current if current.is_a?(String)

        path = Rails.error.handle(ActionController::UrlGenerationError, severity: :info) do
          Context.view_context.url_for(current)
        end

        if path.present?
          options[:href] = path
        elsif settings&.[](:remove_if_invalid)
          options.delete(:href)
          options[:if] = false
        end
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
