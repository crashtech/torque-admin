# frozen_string_literal: true

require_relative 'template/locals_helper'

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Template Helpers
      module Template
        extend ActiveSupport::Concern

        include LocalsHelper
      end
    end
  end
end
