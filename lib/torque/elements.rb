# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/dependencies/autoload'

module Torque
  module Elements
    extend ActiveSupport::Autoload

    autoload :Frame
    autoload :Helpers
    autoload :Templates

    autoload :UiBuilder

    class << self
      def logger
        ActionView::Base.logger
      end

      ## Quick access to configuration methods

      def enable_ui_framework(*args, **kwargs)
        UiBuilder.enable_framework(*args, **kwargs)
      end

      def add_ui_framework(*args, **kwargs)
        UiBuilder.add_framework(*args, **kwargs)
      end
    end
  end
end

require_relative 'elements/errors'
require_relative 'elements/railtie'
