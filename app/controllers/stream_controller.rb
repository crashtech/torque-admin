# frozen_string_literal: true

module Torque
  module Admin
    module StreamController
      extend ActiveSupport::Concern

      Key = :"torque@async"

      included do
        alias_method(:process_sync, :process)
        include(ActionController::Live)
        alias_method(:process_async, :process)
        alias_method(:process, :direct_process)
      end

      class_methods do
        def stream_actions(*actions)
          @async_actions = async_actions + actions.map { |action| action.to_s.freeze }
        end

        def async_actions
          return @async_actions if defined?(@async_actions)

          superclass.respond_to?(:async_actions) ? superclass.async_actions : [].freeze
        end

        def async_action?(action)
          async_actions.include?(action)
        end
      end

      def direct_process(action, ...)
        if async_action?(action)
          process_async(action, ...)
        else
          process_sync(action, ...)
        end
      end

      def process_action(...)
        return super unless async_action?

        begin
          Thread.current[Key] = []
          super
        ensure
          wait_all_async_processes!
          response.stream.close
        end
      end

      protected

        def async_action?(name = action_name)
          self.class.async_action?(name)
        end

        def wait_all_async_processes!
          return yield unless (processor = admin_config.parallel_processing_with)

          error = nil
          Thread.current[Key].each do |process|
            case processor
            when :async
              error ? process.cancel : process.wait
            when :concurrent_ruby
              error ? process.cancel : process.wait!
            else raise "Unknown parallel processing method: #{processor.inspect}"
            end
          rescue Exception => e
            error ||= e
          end

          Thread.current[Key].clear
          raise error if error
          # TODO: Add support for web console making turbo to render it as a new page
        end

        def initialize_async_process(&)
          return yield unless (processor = admin_config.parallel_processing_with)

          list = Thread.current[Key]
          raise +"Async processes cannot be started outside of an async action" unless list

          list <<
            case processor
            when :async then Async(&)
            when :concurrent_ruby
              Concurrent::Future.execute(args: Thread.current) do |t1|
                ActiveSupport::IsolatedExecutionState.share_with(t1, &)
              end
            else
              raise "Unknown parallel processing method: #{processor.inspect}"
            end
        end

    end
  end
end
#
