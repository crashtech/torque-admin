# frozen_string_literal: true

require_relative 'helpers/ui_helper'

module Torque
  module Elements
    # = Torque Elements \Helpers
    #
    # This module includes all global helpers for Torque Elements, available both for templates and regular views
    module Helpers
      extend ActiveSupport::Autoload
      extend ActiveSupport::Concern

      autoload :Template

      autoload :Bootstrap
      autoload :Bulma
      autoload :MaterialUI
      autoload :SemanticUI
      autoload :Tailwind

      include UiHelper
    end
  end
end
