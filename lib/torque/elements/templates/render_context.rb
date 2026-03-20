# frozen_string_literal: true

module Torque
  module Elements
    module Templates
      # = Torque Elements \Template Render Context
      class RenderContext < ActionView::Base
        include Helpers::Template

        delegate :compiled_method_container, to: :class
        delegate_missing_to :@view_context

        module Reloader
          def clear
            super
            RenderContext.instance_variable_set(:@container, nil)
          end
        end

        class << self
          def compiled_method_container
            @container ||= Module.new.tap { |mod| include mod }
          end
        end

        def initialize(*args)
          super(*args)
          @_request = nil
        end

        def inspect
          "#<#{self.class.name}#{'%#016x' % (object_id << 1)}>"
        end
      end
    end
  end
end
