# frozen_string_literal: true

module Torque
  module Forms
    # = Torque Forms \Element
    class Element < Torque::Elements::Base
      def clear!
        @icons_helper = nil
        super
      end

      def type
        :form
      end

      def element_settings
        super + %i[hints icons]
      end

      ## Define nodes

      ## Renderer

      # def sanitize_node_label_options(node)
      #   icons_helper&.call(node)
      # end

      # def sanitize_node_input_options(node)
      #   icons_helper&.call(node)
      # end

      def sanitize_node_button_options(node)
        icons_helper&.call(node)
      end

      ## Others

      def icons_helper
        return @icons_helper if defined?(@icons_helper)

        @icons_helper = build_settings_handler(:icons, :icon)
      end

      protected

        def i18n_keys
        end
    end
  end
end
