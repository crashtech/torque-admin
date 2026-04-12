# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Context
    class Context < ActiveSupport::CurrentAttributes
      attribute :view_context
      attribute :elements
      attribute :refs, default: {}

      before_reset { elements&.clear! }

      def initialized?
        !view_context.nil?
      end

      def with_ref(name, value)
        old_value = refs[name.to_sym]
        add_ref(name, value)
        yield
      ensure
        add_ref(name, old_value)
      end

      def add_ref(name, value)
        refs[name.to_sym] = value.to_s
      end
    end
  end
end
