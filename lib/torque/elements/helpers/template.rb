# frozen_string_literal: true

require_relative 'template/locals_helper'

module Torque
  module Elements
    module Helpers
      # = Torque Elements \Template Helpers
      module Template
        extend ActiveSupport::Concern

        include LocalsHelper

        class Buffer < ActiveSupport::SafeBuffer
          def gsub(*args)
            args[0] == '"' && args[1] == '&quot;' ? self : super
          end
        end

        def append(body)
          Buffer.new("<%= #{body} %>")
        end
      end
    end
  end
end
