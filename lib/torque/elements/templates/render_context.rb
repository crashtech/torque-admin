# frozen_string_literal: true

module Torque
  module Elements
    module Templates
      # = Torque Elements \Template Render Context
      class RenderContext < ActionView::Base
        include Helpers::Template

        attr_reader :view_context

        delegate :compiled_method_container, to: :class
        delegate_missing_to :view_context

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
          @view_context = args.pop
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
