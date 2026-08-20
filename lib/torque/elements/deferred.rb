# frozen_string_literal: true

module Torque
  module Elements
    # = Torque Elements \Deferred
    class Deferred
      attr_reader :callable, :args, :kwargs

      def initialize(callable, *args, **kwargs)
        @callable = callable
        @args = args
        @kwargs = kwargs
      end

      def curry(*args, **kwargs)
        self.class.new(callable, *self.args, *args, **self.kwargs, **kwargs)
      end

      def call(view_context = Context.view_context)
        case callable
        when Symbol then view_context.public_send(callable, *args, **kwargs)
        when Method then callable.call(*args, **kwargs)
        else view_context.instance_exec(*args, **kwargs, &callable)
        end
      end

      def to_proc
        proc { |*args, **kwargs| curry(*args, **kwargs).call }
      end
    end
  end
end
