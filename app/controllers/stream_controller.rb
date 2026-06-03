# frozen_string_literal: true

module Torque
  module Admin
    module StreamController
      extend ActiveSupport::Concern

      Key = :"torque@async"

      included do
        class_attribute :stream_actions, instance_writer: false, default: [].freeze

        alias_method :process_sync, :process
        include ActionController::Live
        alias_method :process_async, :process
        alias_method :process, :process_properly
      end

      class_methods do
        def stream_from_actions(*actions)
          self.stream_actions += actions.flatten.map(&:to_s)
          self.stream_actions.freeze
        end
      end

      def process_properly(action, ...)
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
          Thread.current[Key] = nil
          response.stream.close unless response.stream.closed?
        end
      end

      # TODO: When we are in sream mode, render and default render responses need to be adapted/overload, attempting to
      # keep the same interface but not closing the stream and properly handling subsequent render calls.

      protected

        def async_action?(name = nil)
          (name.nil? && !Thread.current[Key].nil?) || stream_actions.include?((name || action_name).to_s)
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
            end
          rescue Exception => e
            error ||= e
          end

          Thread.current[Key].clear
          raise error if error
          # TODO: Add support for web console and better errors, guiding turbo to render it as a new page
        end

        def initialize_async_process(&)
          return yield unless (processor = admin_config.parallel_processing_with)

          raise +"Async processes cannot be started outside of an async action" if (list = Thread.current[Key]).nil?

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
